# Changelog

## [0.7.0](https://github.com/wsdjeg/nvim-plug/compare/v0.6.0...v0.7.0) (2026-02-21)


### Features

* add luarocks support ([4380019](https://github.com/wsdjeg/nvim-plug/commit/4380019d5da7e6bbeba486b5d343878e1feb597f))
* **config:** add `focus_window` setup option to enable focusing on open ([4f2f116](https://github.com/wsdjeg/nvim-plug/commit/4f2f116aac7d14bd94ebfbebbaa861d15aaa288c))
* display desc in picker source ([6b87d5f](https://github.com/wsdjeg/nvim-plug/commit/6b87d5f5b9cb59df570fe8d9ce201fc48383d427))
* open readme in default picker action ([310aa1d](https://github.com/wsdjeg/nvim-plug/commit/310aa1df90aee86ea871ec1675a96667a5d83e40))
* use luarocks show for rocks preview ([8baa3a7](https://github.com/wsdjeg/nvim-plug/commit/8baa3a745998ef2b7ae058386d4db1ac8e3ae846))


### Bug Fixes

* add debug info about set module name ([a41b120](https://github.com/wsdjeg/nvim-plug/commit/a41b120cb98a87271db3eb68139543ac9ecfb91f))
* change fileformat to unix ([91184b5](https://github.com/wsdjeg/nvim-plug/commit/91184b5b7e8fc246120b4c4754f5b0b1509165d9))
* fix dev_path ([f1db89c](https://github.com/wsdjeg/nvim-plug/commit/f1db89c5e10dbcd11e2d96dc1fa281e03bcc43d5))
* fix LUA_PATH and LUA_CPATH ([094928b](https://github.com/wsdjeg/nvim-plug/commit/094928b575895d1644fb268b82585cc721f6047c))
* fix luarocks installer ([bf70775](https://github.com/wsdjeg/nvim-plug/commit/bf70775ff093f02b17e0b8a05a4eed49d6ab1a3f))
* fix picker default_action ([25f0b87](https://github.com/wsdjeg/nvim-plug/commit/25f0b87b809c63bfd25269e938c448d07e2b7894))
* format code ([484bf1e](https://github.com/wsdjeg/nvim-plug/commit/484bf1e2318e6ac7444b4d1ced01a1e2673f200c))
* format lua code and handle lsp warnings ([edef4e4](https://github.com/wsdjeg/nvim-plug/commit/edef4e43bd0630a76315fdd69e9bfb49f8fb5a9e))
* remove lower() function ([eaace1e](https://github.com/wsdjeg/nvim-plug/commit/eaace1e0429e1762038ecf66ad2f104f969c3764))
* **ui:** optimize UI, add keymap to close UI ([7d5d98a](https://github.com/wsdjeg/nvim-plug/commit/7d5d98a359865c2b0166578e7709264e3c4a1fe9))
* update/improve LuaLS annotations, optimized code execution ([8a0799d](https://github.com/wsdjeg/nvim-plug/commit/8a0799d74766992916bd082d7832f19d15fb78eb))

## [0.6.0](https://github.com/wsdjeg/nvim-plug/compare/v0.5.0...v0.6.0) (2025-11-22)


### Features

* add on_map desc ([b329373](https://github.com/wsdjeg/nvim-plug/commit/b32937333e4783ea74139e2d8e57d4984c36d573))


### Bug Fixes

* fix `:Plug update` ([a949e99](https://github.com/wsdjeg/nvim-plug/commit/a949e9958f4e0c4a921fbfa33f158fefdfd35e0c))
* fix on_map logic ([6f2ea6b](https://github.com/wsdjeg/nvim-plug/commit/6f2ea6b1465be9737c35efd9cbae6d47b5809731))
* fix PluginSpec field ([7e3722a](https://github.com/wsdjeg/nvim-plug/commit/7e3722aa2377c79afd4e53182c2d75115d9b52de))

## [0.5.0](https://github.com/wsdjeg/nvim-plug/compare/v0.4.0...v0.5.0) (2025-10-30)


### Features

* add _tabnew_lcd action ([cc6596f](https://github.com/wsdjeg/nvim-plug/commit/cc6596fe17f16fc8591993b2cdee89f8d5877aa8))
* add `:Plug` command and subcommands ([475f253](https://github.com/wsdjeg/nvim-plug/commit/475f2533ec0d7681320856a1918624ede08daabf))
* add `ctrl-y` for picker source ([b9be73a](https://github.com/wsdjeg/nvim-plug/commit/b9be73a9e9af69cf4662c000d25199a6fb836dd5))
* add `keys` and `opts` to plugSpec ([9f24aba](https://github.com/wsdjeg/nvim-plug/commit/9f24aba5b30741216570be14e28d16848f806898))
* add actions for picker source ([f894a3b](https://github.com/wsdjeg/nvim-plug/commit/f894a3b7cda80c2ae989d5c1a6f75e46aec65926))
* add clock module ([6694d34](https://github.com/wsdjeg/nvim-plug/commit/6694d3471d07f71b7fa6dc7ea804897d87478c7e))
* add picker source ([60dec62](https://github.com/wsdjeg/nvim-plug/commit/60dec62a752f0d1dd7994307ac16dfe0e1081a48))
* add plugSpec.dev ([1db4403](https://github.com/wsdjeg/nvim-plug/commit/1db4403c91ab17fb774d9de1ce3e2805285d9afd))
* support load_time in plugSpec ([6575e79](https://github.com/wsdjeg/nvim-plug/commit/6575e79b091675125791b62731c2b9f49f95dd6c))


### Bug Fixes

* fix get_default_module function ([e75894c](https://github.com/wsdjeg/nvim-plug/commit/e75894ce06c071979748a7c2fd29b7df78112599))
* fix known project.path ([018f177](https://github.com/wsdjeg/nvim-plug/commit/018f17723ecc3443844a91bd256b55a3ff26ac2d))
* fix terminal mode ([ca10edf](https://github.com/wsdjeg/nvim-plug/commit/ca10edf8c03bad7fa2876d713697a8b5464c20dd))
* handle opts setup error ([62eb5df](https://github.com/wsdjeg/nvim-plug/commit/62eb5dff7e51751795e2cf0d5b55177d50b69b59))
* make sure keys init before lazy cmd ([cdbfae7](https://github.com/wsdjeg/nvim-plug/commit/cdbfae754b6a07b47f75c4ba409d5bd57a808abd))
* set dev_path ([50c4a93](https://github.com/wsdjeg/nvim-plug/commit/50c4a9328aad4c15249b4c43a1968fac0a7dfb97))
* startinsert in terminal ([636d488](https://github.com/wsdjeg/nvim-plug/commit/636d488ac834a6fb82f9104038a3ff401fe079e0))

## [0.4.0](https://github.com/wsdjeg/nvim-plug/compare/v0.3.1...v0.4.0) (2025-09-20)


### Features

* **core:** remove spacevim.api.job ([64e9a6c](https://github.com/wsdjeg/nvim-plug/commit/64e9a6c071ab5449d3af708301e554ef48bb390d))
* **log:** support runtime log ([f166a61](https://github.com/wsdjeg/nvim-plug/commit/f166a617bc486b207b38e44dae92e0892740a4bf))
* support import option ([#8](https://github.com/wsdjeg/nvim-plug/issues/8)) ([3bce0a7](https://github.com/wsdjeg/nvim-plug/commit/3bce0a7aa130e4296b6a0e7e956341e8dfa667cf))


### Bug Fixes

* **loader:** fix enabled field ([b6bb459](https://github.com/wsdjeg/nvim-plug/commit/b6bb459dfd1308103a61bb7a8dcc161206211ae8))

## [0.3.1](https://github.com/wsdjeg/nvim-plug/compare/v0.3.0...v0.3.1) (2025-04-13)


### Bug Fixes

* fix default base_url ([0541528](https://github.com/wsdjeg/nvim-plug/commit/05415284ff2258bb356fdddfdf337b60ff1ac252))
* **on_cmd:** clear lazy cmd when load plugin ([19b043e](https://github.com/wsdjeg/nvim-plug/commit/19b043e967c11e886f73d8edf661d5dfd4468533))

## [0.3.0](https://github.com/wsdjeg/nvim-plug/compare/v0.2.0...v0.3.0) (2025-03-19)


### Features

* **ui:** support notify.nvim ([69b7886](https://github.com/wsdjeg/nvim-plug/commit/69b7886942923901499544ccced15602305a936a))

## [0.2.0](https://github.com/wsdjeg/nvim-plug/compare/v0.1.1...v0.2.0) (2025-03-13)


### Features

* **easing:** use easing function in notify ([6a2ec66](https://github.com/wsdjeg/nvim-plug/commit/6a2ec668cdf7c64f039d6e33b65272b0fb1863cc))
* **nvim-plug:** add `fetch` option ([7a549aa](https://github.com/wsdjeg/nvim-plug/commit/7a549aa591f22b8b607ec037776634a27a5112da))


### Bug Fixes

* **nvim-plug:** fix buf modifiable opt ([3c2bbbb](https://github.com/wsdjeg/nvim-plug/commit/3c2bbbb2ca7ecdead129b32c98a4069cad7a1e87))
* **nvim-plug:** make sure buf modifiable is true ([b9fdb00](https://github.com/wsdjeg/nvim-plug/commit/b9fdb005b895cab15d5cf23ef7d8b96303821755))
* **nvim-plug:** typo ([7978b61](https://github.com/wsdjeg/nvim-plug/commit/7978b61eff861f1550e8cc7791ffb40db7e7dbb2))
* skip none git repo ([d7d3ed9](https://github.com/wsdjeg/nvim-plug/commit/d7d3ed912300fd085c70f2d638831b31838d37fd))
