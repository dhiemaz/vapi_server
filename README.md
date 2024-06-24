# VapiServer

Testing Repository for a VapiServer.

## Start

To run use

```bash
mix phx.server
```

To connect to Vapi install ngrok and run
```bash
ngrok http 4000
```
Copy paste the https address you see on the console and copy it into the custom-llm in your assistant under module.


## TODO

- [x] Initialize Phoenix 1.7 template with completion route
- [x] Connect VAPI as custom model
- [x] Stream responses
- [x] Install [NgrokEx](https://github.com/joshuafleck/ex_ngrok) and Use VapiAPI to do a dev setup and connect dev-assistant.
- [x] Connect to groq to receive answers
- [ ] Store Message for a retrieval on a later phone call (in GenServer)
- [ ] Restore context on next call
- [ ] Allow Function Calling in Server
- [ ] Connect Phone Number and Dispatch Calls
- [ ] Send E-Mail for multi chanel test
- [ ] Dispatch Children to FLAME Backend
