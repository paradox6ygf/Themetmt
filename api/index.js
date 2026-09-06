const fs = require('fs');
const path = require('path');

module.exports = (req, res) => {
    const scriptPath = path.join(__dirname, '..', 'setup.sh');
    try {
        const content = fs.readFileSync(scriptPath, 'utf8');
        res.setHeader('Content-Type', 'text/plain; charset=utf-8');
        res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
        res.status(200).send(content);
    } catch (err) {
        res.status(500).send('# Error: Could not load setup script\n');
    }
};
