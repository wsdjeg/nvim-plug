# Changelog

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
