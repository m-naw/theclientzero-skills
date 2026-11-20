// Tiny user service. Port from APP_PORT (default 8080).
const http = require('http');
const fs = require('fs');
const path = require('path');

const load = () => JSON.parse(fs.readFileSync(path.join(__dirname, 'data', 'users.json'), 'utf8'));
const send = (res, code, body) => {
  res.writeHead(code, { 'content-type': 'application/json' });
  res.end(JSON.stringify(body));
};

const server = http.createServer((req, res) => {
  const url = new URL(req.url, 'http://x');
  if (req.method === 'GET' && url.pathname === '/health') return send(res, 200, { ok: true });
  if (req.method === 'GET' && url.pathname === '/users') {
    return send(res, 200, { users: load().map(({ id, name }) => ({ id, name })) });
  }
  send(res, 404, { error: 'not_found' });
});

server.on('error', (e) => { console.error('ERROR ' + e.message); process.exit(1); });
server.listen(Number(process.env.APP_PORT || 8080), () => console.log('listening ' + server.address().port));
