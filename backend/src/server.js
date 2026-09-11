require('dotenv').config();

const app = require('./app');
const { connectDb } = require('./db');

const port = process.env.PORT || 4000;

connectDb()
  .then(() => {
    app.listen(port, () => console.log(`[server] DODOMED API listening on :${port}`));
  })
  .catch((err) => {
    console.error('[server] failed to connect to MongoDB:', err.message);
    process.exit(1);
  });
