# Ride Client (TypeScript)

Client TypeScript minimal pour communiquer avec le `ride-service` de MoveX.

Installation

```bash
cd clients/ride-client-ts
npm install
npm run build
```

Usage (exemple)

```ts
import RideClient from 'ride-client-ts/dist'

async function demo(){
  const c = new RideClient({ baseURL: 'http://localhost:8080' })
  console.log(await c.health())
  const ride = await c.createRide({ passenger: '+237600000000' })
  console.log('created', ride)
  const got = await c.getRide(ride.id)
  console.log('got', got)
}

demo()
```

Notes
- Ce client est volontairement minimal — il fournit des wrappers Axios typés pour les endpoints exposés par `ride-service`.
- Vous pouvez étendre les types et ajouter gestion des erreurs, interceptors, authentification, etc.
