<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Digital Shield Corp — Client Portal</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:'Segoe UI',sans-serif;background:#0a1628;color:#c8d6e5}
.header{background:#111d32;border-bottom:1px solid #1a2d4a;padding:20px 40px}
.header h1{color:#00b4d8;font-size:20px}
.header p{color:#5a6f8a;font-size:12px}
.container{max-width:800px;margin:40px auto;padding:0 20px}
.card{background:#111d32;border:1px solid #1a2d4a;border-radius:10px;padding:24px;margin-bottom:16px}
.card h3{color:#00b4d8;margin-bottom:8px}
.card p{color:#8b9dc3;font-size:13px;line-height:1.6}
a{color:#00b4d8}
.footer{text-align:center;padding:40px;color:#3d5272;font-size:11px}
</style>
</head>
<body>
<div class="header">
<h1>🛡️ Digital Shield — Client Portal</h1>
<p>Secure document exchange for authorized clients</p>
</div>
<div class="container">
<div class="card">
<h3>📋 Service Reports</h3>
<p>Access your penetration test reports and vulnerability assessments.</p>
<p style="margin-top:8px"><a href="/reports/">View Reports</a></p>
</div>
<div class="card">
<h3>📊 Dashboard</h3>
<p>Server Status: <span style="color:#10b981">Online</span></p>
<p>PHP Version: <?php echo phpversion(); ?></p>
<p>Server: <?php echo $_SERVER['SERVER_SOFTWARE']; ?></p>
</div>
<div class="card">
<h3>🔒 Admin Panel</h3>
<p>Internal administration — <a href="/admin/">Login Required</a></p>
</div>
</div>
<div class="footer">Digital Shield Corporation — Client Portal v3.1</div>
</body>
</html>
