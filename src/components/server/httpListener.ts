import type { RequestListener } from 'http';

export const httpListener: RequestListener = (req, res) => {
  if (req.url!.startsWith('/healthz')) {
    res.writeHead(200).end();
  } else {
    res.writeHead(404).end();
  }
};
