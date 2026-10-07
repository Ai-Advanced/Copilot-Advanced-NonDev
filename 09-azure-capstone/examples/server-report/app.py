"""Read-only training report with synthetic data; no uploads or external systems."""

from html import escape
from urllib.parse import parse_qs

SALES = {"영업": 120, "마케팅": 80, "운영": 50}


def app(environ, start_response):
    if environ.get("REQUEST_METHOD") != "GET":
        start_response("405 Method Not Allowed", [("Allow", "GET"), ("Content-Type", "text/plain; charset=utf-8")])
        return ["조회만 지원합니다.".encode("utf-8")]
    if environ.get("PATH_INFO") != "/":
        start_response("404 Not Found", [("Content-Type", "text/plain; charset=utf-8")])
        return ["페이지를 찾을 수 없습니다.".encode("utf-8")]
    department = parse_qs(environ.get("QUERY_STRING", "")).get("department", ["전체"])[0]
    if department != "전체" and department not in SALES:
        start_response("400 Bad Request", [("Content-Type", "text/plain; charset=utf-8")])
        return ["지원하지 않는 부서입니다.".encode("utf-8")]
    rows = SALES if department == "전체" else {department: SALES[department]}
    options = "".join(
        f'<option{" selected" if name == department else ""}>{escape(name)}</option>'
        for name in ["전체", *SALES]
    )
    items = "".join(f"<li>{escape(name)}: {value}만원</li>" for name, value in rows.items())
    body = f"""<!doctype html><html lang="ko"><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>가상 부서 매출 보고서</title>
<h1>가상 부서 매출 보고서</h1><p>교육용 고정 샘플 · 실제 재무 데이터 아님 · lab-v1</p>
<form><label>부서 <select name="department">{options}</select></label>
<button>조회</button></form><ul>{items}</ul><p>합계: {sum(rows.values())}만원</p>
<p>이 합계는 Python 서버에서 계산합니다.</p></html>""".encode("utf-8")
    start_response("200 OK", [
        ("Content-Type", "text/html; charset=utf-8"),
        ("Content-Length", str(len(body))),
        ("Cache-Control", "no-store"),
        ("X-Content-Type-Options", "nosniff"),
    ])
    return [body]


if __name__ == "__main__":
    from wsgiref.simple_server import make_server

    with make_server("127.0.0.1", 8000, app) as server:
        print("Local training preview: http://127.0.0.1:8000")
        server.serve_forever()
