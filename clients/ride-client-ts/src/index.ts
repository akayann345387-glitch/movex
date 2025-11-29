import axios, { AxiosInstance } from 'axios'

// Types
export type RideState = 'requested' | 'accepted' | 'started' | 'completed'

export interface Ride {
  id: string
  passenger: string
  driver?: string | null
  state: RideState
  created_at: string
}

export interface RideCreate {
  passenger: string
}

export interface ClientOptions {
  baseURL?: string
  timeoutMs?: number
}

export class RideClient {
  private http: AxiosInstance

  constructor(opts?: ClientOptions) {
    this.http = axios.create({
      baseURL: opts?.baseURL ?? 'http://localhost:8080',
      timeout: opts?.timeoutMs ?? 5000,
      headers: { 'Content-Type': 'application/json' }
    })
  }

  async health(): Promise<{ status: string }> {
    const r = await this.http.get('/health')
    return r.data
  }

  async createRide(payload: RideCreate): Promise<Ride> {
    const r = await this.http.post('/rides', payload)
    return r.data
  }

  async getRide(id: string): Promise<Ride> {
    const r = await this.http.get(`/rides/${id}`)
    return r.data
  }

  async acceptRide(id: string): Promise<Ride> {
    const r = await this.http.post(`/rides/${id}/accept`)
    return r.data
  }

  async startRide(id: string): Promise<Ride> {
    const r = await this.http.post(`/rides/${id}/start`)
    return r.data
  }

  async completeRide(id: string): Promise<Ride> {
    const r = await this.http.post(`/rides/${id}/complete`)
    return r.data
  }
}

export default RideClient
