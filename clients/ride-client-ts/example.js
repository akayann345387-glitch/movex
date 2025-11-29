// example.js — simple run using the built client
const RideClient = require('./dist').default || require('./dist');

(async () => {
  try {
    const c = new RideClient({ baseURL: 'http://localhost:8080' });
    const h = await c.health();
    console.log('health:', h);
    const ride = await c.createRide({ passenger: '+237600000000' });
    console.log('created ride:', ride);
    const got = await c.getRide(ride.id);
    console.log('fetched ride:', got);
  } catch (err) {
    console.error('example error:', err.message || err);
    process.exitCode = 1;
  }
})();
