ngx.header.content_type = "text/plain"
ngx.print("Written from lua!\n")
ngx.print(tostring(ngx.req.get_headers()['authorization'].split(" ")[1]))
ngx.exit(0)
