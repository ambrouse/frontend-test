from __future__ import annotations

import json
import re
import time
from pathlib import Path
from typing import Any
from urllib.request import Request, urlopen

from playwright.sync_api import Page, sync_playwright


ROOT = Path(__file__).resolve().parents[1]
# Legacy smoke harness output is intentionally transient. Curated, reviewable
# evidence lives under test/provider-post-push-pipeline-evidence-2026-05-22.
BASE = ROOT / "test-results" / "provider-functional-smoke"
API_BASE = "http://127.0.0.1:8000"
UI_BASE = "http://127.0.0.1:3000"
CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
PROGRESS = BASE / "_reports" / "functional-validation-progress.log"
SUMMARY = BASE / "_reports" / "functional-validation-summary.json"

PROVIDERS = [
    {
        "id": "shop-retail-provider",
        "name": "Shop Retail Provider",
        "app": "http://127.0.0.1:13100",
        "kind": "chat",
        "prompt": "Do you have any summer skirts?",
        "wait": 150,
    },
    {
        "id": "agentic-commerce-blueprint",
        "name": "Agentic Commerce Blueprint",
        "app": "http://127.0.0.1:8088",
        "kind": "chat",
        "prompt": "Show me available products and help me start a checkout for one item.",
        "wait": 150,
    },
    {
        "id": "ai-virtual-assistant-provider",
        "name": "AI Virtual Assistant Provider",
        "app": "http://127.0.0.1:13301",
        "kind": "chat",
        "prompt": "How can I reset my account password?",
        "wait": 180,
    },
    {
        "id": "aiq",
        "name": "NVIDIA AI-Q Blueprint",
        "app": "http://127.0.0.1:13080",
        "kind": "chat",
        "prompt": "Explain retrieval augmented generation in two short bullet points.",
        "wait": 180,
    },
    {
        "id": "multi-agent-intelligent-warehouse",
        "name": "Multi-Agent Intelligent Warehouse",
        "app": "http://127.0.0.1:13003",
        "kind": "warehouse",
        "wait": 60,
    },
    {
        "id": "web-agent",
        "name": "Web Agent",
        "app": "http://127.0.0.1:3005",
        "kind": "chat",
        "prompt": "Search the web for NVIDIA AI Enterprise and summarize one useful result.",
        "wait": 120,
    },
]


def read_secret_values() -> list[str]:
    values: list[str] = []
    env_path = ROOT / ".env.local"
    if env_path.exists():
        for line in env_path.read_text(encoding="utf-8-sig", errors="ignore").splitlines():
            if "=" not in line or line.strip().startswith("#"):
                continue
            value = line.split("=", 1)[1].strip()
            if value:
                values.append(value)
    return values


SECRETS = read_secret_values()


def sanitize(text: str) -> str:
    clean = text
    for secret in SECRETS:
        clean = clean.replace(secret, "***")
    return re.sub(r"nvapi-[A-Za-z0-9_\-]+", "nvapi-***", clean)


def log(message: str) -> None:
    line = f"{time.strftime('%Y-%m-%d %H:%M:%S')} {message}"
    print(line, flush=True)
    PROGRESS.parent.mkdir(parents=True, exist_ok=True)
    with PROGRESS.open("a", encoding="utf-8") as handle:
        handle.write(sanitize(line) + "\n")


def api(path: str, method: str = "GET", body: dict[str, Any] | None = None, timeout: int = 30) -> Any:
    data = None if body is None else json.dumps(body).encode("utf-8")
    req = Request(
        f"{API_BASE}{path}",
        data=data,
        method=method,
        headers={"Accept": "application/json", **({"Content-Type": "application/json"} if data else {})},
    )
    with urlopen(req, timeout=timeout) as response:
        raw = response.read().decode("utf-8", errors="replace")
    return json.loads(raw) if raw else None


def wait_idle(provider_id: str, timeout_seconds: int) -> dict[str, Any]:
    deadline = time.time() + timeout_seconds
    last_step = ""
    while time.time() < deadline:
        tasks = api("/api/tasks/active", timeout=10).get("tasks", [])
        active = [task for task in tasks if task.get("projectId") == provider_id]
        status = api(f"/api/providers/{provider_id}/status", timeout=10)
        step = status.get("currentStep") or status.get("state") or ""
        if step != last_step:
            log(f"{provider_id}: {step}")
            last_step = step
        if not active:
            return status
        if any(task.get("status") == "failed" for task in active):
            return status
        time.sleep(5)
    raise TimeoutError(f"{provider_id} did not become idle within {timeout_seconds}s")


def action(provider_id: str, action_name: str, timeout_seconds: int) -> dict[str, Any]:
    if action_name == "delete":
        try:
            api(f"/api/providers/{provider_id}", method="DELETE", body={"force": True}, timeout=15)
        except Exception as exc:
            log(f"{provider_id}: delete request warning {sanitize(str(exc))}")
    else:
        api(f"/api/providers/{provider_id}/{action_name}", method="POST", body={"force": True}, timeout=15)
    return wait_idle(provider_id, timeout_seconds)


def clean_provider_evidence(provider_id: str) -> None:
    provider_dir = BASE / provider_id
    provider_dir.mkdir(parents=True, exist_ok=True)
    root = BASE.resolve()
    target = provider_dir.resolve()
    if root not in target.parents and root != target:
        raise RuntimeError(f"Refusing to clean unexpected path: {target}")
    for file in provider_dir.rglob("*"):
        if file.is_file():
            file.unlink()
    for folder in ("lifecycle", "logs", "app", "function"):
        (provider_dir / folder).mkdir(parents=True, exist_ok=True)


def shot(page: Page, provider_id: str, folder: str, name: str) -> str:
    path = BASE / provider_id / folder / f"{name}.png"
    path.parent.mkdir(parents=True, exist_ok=True)
    page.screenshot(path=str(path), full_page=True)
    return str(path.relative_to(ROOT))


def detail(page: Page, provider_id: str) -> None:
    page.goto(f"{UI_BASE}/hub/{provider_id}", wait_until="domcontentloaded", timeout=60_000)
    page.wait_for_timeout(2500)


def capture_hub_and_logs(page: Page, provider_id: str) -> dict[str, Any]:
    result: dict[str, Any] = {"screenshots": []}
    detail(page, provider_id)
    result["screenshots"].append(shot(page, provider_id, "lifecycle", "hub-detail-running"))
    sources = api(f"/api/providers/{provider_id}/service-logs/sources", timeout=20)
    logs = api(f"/api/providers/{provider_id}/service-logs?tail=80", timeout=30)
    result["sourceCount"] = len(sources.get("sources", []))
    result["availableSources"] = [
        source.get("id") for source in sources.get("sources", []) if source.get("available")
    ]
    result["logLineCount"] = len(logs.get("logs", []))
    result["logSample"] = sanitize("\n".join(item.get("message", "") for item in logs.get("logs", [])[-10:]))
    page.get_by_role("tab", name=re.compile("Service logs", re.I)).click(timeout=10_000)
    page.wait_for_timeout(3000)
    result["screenshots"].append(shot(page, provider_id, "logs", "service-logs-streaming"))
    return result


def meaningful_response(before: str, after: str, prompt: str) -> bool:
    if len(after) < len(before) + 80:
        return False
    tail = after[len(before) :].strip()
    if not tail:
        return False
    normalized_tail = re.sub(r"\s+", " ", tail).lower()
    normalized_prompt = re.sub(r"\s+", " ", prompt).lower()
    if normalized_tail == normalized_prompt or normalized_tail.endswith(normalized_prompt):
        return False
    bad_needles = ["type something here", "here are some questions you could ask me"]
    return not all(needle in normalized_tail for needle in bad_needles)


def submit_prompt(page: Page, prompt: str) -> bool:
    locator = page.locator("textarea, input:not([type=hidden]):not([type=password]), [contenteditable=true]")
    candidates: list[tuple[int, float]] = []
    for index in range(locator.count()):
        element = locator.nth(index)
        try:
            if element.is_visible(timeout=800) and element.is_enabled(timeout=800):
                box = element.bounding_box()
                candidates.append((index, box["y"] if box else 0))
        except Exception:
            continue
    candidates.sort(key=lambda item: item[1], reverse=True)
    if not candidates:
        return False
    element = locator.nth(candidates[0][0])
    element.click(timeout=5000)
    try:
        element.fill(prompt, timeout=5000)
    except Exception:
        page.keyboard.type(prompt)
    for pattern in ("Send", "Submit", "Ask", "Search", "Chat", "Run", "Start"):
        try:
            button = page.get_by_role("button", name=re.compile(pattern, re.I)).first
            if button.is_visible(timeout=800) and button.is_enabled(timeout=800):
                button.click(timeout=5000)
                return True
        except Exception:
            continue
    page.keyboard.press("Enter")
    return True


def run_chat_function(page: Page, provider: dict[str, Any]) -> dict[str, Any]:
    provider_id = provider["id"]
    prompt = provider["prompt"]
    page.goto(provider["app"], wait_until="domcontentloaded", timeout=60_000)
    page.wait_for_timeout(5000)
    home = shot(page, provider_id, "app", "app-home")
    before = page.locator("body").inner_text(timeout=10_000)
    submitted = submit_prompt(page, prompt)
    prompt_shot = shot(page, provider_id, "function", "prompt-submitted")
    ok = False
    after = before
    deadline = time.time() + int(provider.get("wait", 120))
    while time.time() < deadline:
        page.wait_for_timeout(5000)
        after = page.locator("body").inner_text(timeout=10_000)
        if meaningful_response(before, after, prompt):
            ok = True
            break
    output_shot = shot(page, provider_id, "function", "function-output" if ok else "function-no-output")
    (BASE / provider_id / "function" / "function-text.txt").write_text(sanitize(after[-5000:]), encoding="utf-8")
    return {
        "home": home,
        "promptShot": prompt_shot,
        "outputShot": output_shot,
        "ok": ok,
        "submitted": submitted,
        "textSample": sanitize(after[-1500:]),
    }


def run_warehouse_function(page: Page, provider: dict[str, Any]) -> dict[str, Any]:
    provider_id = provider["id"]
    page.goto(provider["app"], wait_until="domcontentloaded", timeout=60_000)
    page.wait_for_timeout(3000)
    home = shot(page, provider_id, "app", "app-login")
    page.get_by_label(re.compile("username", re.I)).fill("admin", timeout=10_000)
    page.get_by_label(re.compile("password", re.I)).fill("changeme", timeout=10_000)
    page.get_by_role("button", name=re.compile("sign in|login", re.I)).click(timeout=10_000)
    page.wait_for_timeout(8000)
    dashboard = shot(page, provider_id, "function", "function-dashboard-after-login")
    body = page.locator("body").inner_text(timeout=10_000)
    (BASE / provider_id / "function" / "function-text.txt").write_text(sanitize(body[-5000:]), encoding="utf-8")
    ok = bool(re.search(r"dashboard|warehouse|inventory|orders|agents|admin", body, re.I)) and "Sign In" not in body[:500]
    return {"home": home, "outputShot": dashboard, "ok": ok, "textSample": sanitize(body[-1500:])}


def validate_provider(page: Page, provider: dict[str, Any]) -> dict[str, Any]:
    provider_id = provider["id"]
    clean_provider_evidence(provider_id)
    entry: dict[str, Any] = {"name": provider["name"], "startedAt": time.strftime("%Y-%m-%dT%H:%M:%S")}
    log(f"{provider_id}: begin")
    action(provider_id, "delete", 1200)
    entry["installStatus"] = action(provider_id, "install", 3600)
    entry["runStatus"] = action(provider_id, "run", 3600)
    if entry["runStatus"].get("state") != "running":
        entry["result"] = "run_failed"
        return entry
    entry["hubAndLogs"] = capture_hub_and_logs(page, provider_id)
    if provider["kind"] == "warehouse":
        entry["function"] = run_warehouse_function(page, provider)
    else:
        entry["function"] = run_chat_function(page, provider)
    entry["result"] = "validated" if entry["function"].get("ok") else "function_no_output"
    action(provider_id, "stop", 1200)
    return entry


def main() -> int:
    summary = {"startedAt": time.strftime("%Y-%m-%dT%H:%M:%S"), "providers": {}}
    if SUMMARY.exists():
        try:
            summary = json.loads(SUMMARY.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            pass
    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(headless=True, executable_path=CHROME)
        page = browser.new_page(viewport={"width": 1440, "height": 1000})
        for provider in PROVIDERS:
            entry = validate_provider(page, provider)
            summary["providers"][provider["id"]] = entry
            SUMMARY.write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")
        browser.close()
    summary["completedAt"] = time.strftime("%Y-%m-%dT%H:%M:%S")
    SUMMARY.write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")
    log("functional evidence run complete")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
