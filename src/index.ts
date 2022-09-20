import http from 'http';

import config from 'config';
import { httpListener } from '!components/server/httpListener';

const address = config.get<string>('server.address');
const port = config.get<number>('server.port');

const server = http.createServer(httpListener);

server.listen(port, address, () => {
  console.log(`Server is running on ${address}:${port}.`);
});
