import http.server
import json
import urllib.request
import shutil

class FixHandler(http.server.BaseHTTPRequestHandler):
    def do_HEAD(self):
        self.send_response(200)
        self.end_headers()

    def do_POST(self):
        content_length = int(self.headers.get('Content-Length', 0))
        post_data = self.rfile.read(content_length)
        
        # 1. 处理 count_tokens 端点探测 (拦截并伪造响应)
        if "count_tokens" in self.path:
            print("🛡️ 拦截到 count_tokens 请求，正在返回伪造响应...")
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            # 返回一个符合格式的假 token 计数
            self.wfile.write(json.dumps({"input_tokens": 100}).encode('utf-8'))
            return

        # 2. 修改请求体：注入必要的参数
        try:
            req_data = json.loads(post_data.decode('utf-8'))
            # 如果 LM Studio 报错缺少 max_tokens，我们强制注入
            if 'max_tokens' not in req_data:
                req_data['max_tokens'] = 4096  # 给一个安全的默认值
                print("💉 已注入缺失的 max_tokens 参数")
            
            # 重新序列化
            post_data = json.dumps(req_data).encode('utf-8')
        except Exception as e:
            print(f"⚠️ 解析请求体失败: {e}")

        # 3. 转发至 LM Studio
        target_url = "http://localhost:1234/v1/messages"
        headers = {'Content-Type': 'application/json', 'Accept': 'text/event-stream'}
        req = urllib.request.Request(target_url, data=post_data, headers=headers, method='POST')
        
        try:
            with urllib.request.urlopen(req) as response:
                self.send_response(200)
                self.send_header('Content-Type', 'text/event-stream')
                self.end_headers()
                print("⏳ 5090 正在处理核心逻辑...")
                shutil.copyfileobj(response, self.wfile)
                print("✅ 转发成功")
        except Exception as e:
            print(f"❌ 转发失败: {e}")
            self.send_error(500, str(e))

print("Claude Code 5090 专线代理 v5.0 [逻辑注入模式] 启动...")
http.server.HTTPServer(('127.0.0.1', 1235), FixHandler).serve_forever()