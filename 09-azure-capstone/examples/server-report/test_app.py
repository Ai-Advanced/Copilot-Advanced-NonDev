import unittest
from urllib.parse import urlencode

from app import app


class ReportTests(unittest.TestCase):
    def request(self, query="", path="/", method="GET"):
        response = {}

        def start(status, headers):
            response["status"] = status
            response["headers"] = dict(headers)

        response["body"] = b"".join(app({
            "REQUEST_METHOD": method, "PATH_INFO": path, "QUERY_STRING": query
        }, start)).decode("utf-8")
        return response

    def test_total(self):
        response = self.request()
        self.assertEqual(response["status"], "200 OK")
        self.assertIn("합계: 250만원", response["body"])

    def test_filter(self):
        response = self.request(urlencode({"department": "영업"}))
        self.assertIn("합계: 120만원", response["body"])
        self.assertNotIn("<li>마케팅", response["body"])

    def test_unknown_department_is_rejected(self):
        response = self.request(urlencode({"department": "<script>alert(1)</script>"}))
        self.assertEqual(response["status"], "400 Bad Request")
        self.assertNotIn("<script>", response["body"])

    def test_unknown_path(self):
        self.assertEqual(self.request(path="/missing")["status"], "404 Not Found")

    def test_post_is_rejected(self):
        self.assertEqual(self.request(method="POST")["status"], "405 Method Not Allowed")


if __name__ == "__main__":
    unittest.main()
