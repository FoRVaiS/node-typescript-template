import { IncomingMessage, ServerResponse } from 'http';

import { httpListener } from '!components/server/httpListener';

const fakeRequest = (url: string): IncomingMessage => ({
  url,
}) as unknown as IncomingMessage;

const fakeResponse = (): ServerResponse => ({
  writeHead: jest.fn().mockImplementation(() => ({
    end: jest.fn(),
  })),
}) as unknown as ServerResponse;

it('should return 404 on the catch-all route', () => {
  const request = fakeRequest('/');
  const response = fakeResponse();

  httpListener(request, response);

  expect(response.writeHead).toBeCalledTimes(1);
  expect(response.writeHead).toBeCalledWith(404);
});

it('should return 200 on the "healthz" route', () => {
  const request = fakeRequest('/healthz');
  const response = fakeResponse();

  httpListener(request, response);

  expect(response.writeHead).toBeCalledTimes(1);
  expect(response.writeHead).toBeCalledWith(200);
});
