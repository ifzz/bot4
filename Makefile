SHELL := /bin/bash

release:
	git submodule update --init
	rm -rf dist
	mkdir dist
	mkdir dist/lib

	# Run the configurator if no settings exist from a previous run
	if [[ ! -f configurator/settings.json ]]; then cd configurator && cargo run; fi;

	# build the bot's utility library and copy into dist/lib
	cd util && cargo build --release
	cp util/target/release/libalgobot_util.so dist/lib
	# copy libstd to the dist/lib directory
	cp $$(find $$(rustc --print sysroot)/lib | grep -E "libstd-.*\.so" | head -1) dist/lib

	# build the FXCM shim
	cd util/src/trading/broker/shims/FXCM/native/native && ./build.sh
	cp util/src/trading/broker/shims/FXCM/native/native/dist/* dist/lib
	cd util/src/trading/broker/shims/FXCM/native && cargo build --release
	cp util/src/trading/broker/shims/FXCM/native/target/release/libfxcm.so dist/lib

	# build all modules and copy their binaries into the dist directory
	cd backtester && cargo build --release
	cp backtester/target/release/backtester dist
	cd spawner && cargo build --release
	cp spawner/target/release/spawner dist
	cd tick_parser && cargo build --release
	cp tick_parser/target/release/tick_processor dist
	cd optimizer && cargo build --release
	cp optimizer/target/release/optimizer dist
	cd logger && cargo build --release
	cp logger/target/release/logger dist
	cd mm && npm install
	cp ./mm dist -r
	cd private && cargo build --release
	cp private/target/release/libprivate.so dist/lib

	# build the FXCM native data downloader
	cd data_downloaders/fxcm_native && cargo build --release
	cp data_downloaders/fxcm_native/target/release/fxcm_native dist/fxcm_native_downloader

dev:
	rm dist/mm -r
	cd dist && ln -s ../mm/ ./mm

debug:
	git submodule update --init
	rm -rf dist
	mkdir dist
	mkdir dist/lib

	# build the configurator
	cd configurator && RUSTFLAGS="-L ../util/target/debug/deps -L ../dist/lib -C prefer-dynamic" cargo build

	# build the bot's utility library and copy into dist/lib
	cd util && cargo build
	cp util/target/debug/libalgobot_util.so dist/lib
	# copy libstd to the dist/lib directory
	cp $$(find $$(rustc --print sysroot)/lib | grep -E "libstd-.*\.so" | head -1) dist/lib

	# build the FXCM shim
	cd util/src/trading/broker/shims/FXCM/native/native && ./build.sh
	cp util/src/trading/broker/shims/FXCM/native/native/dist/* dist/lib
	cd util/src/trading/broker/shims/FXCM/native && RUSTFLAGS="-L ../../../../../../../util/target/debug/deps -L ../../../../../../../dist/lib -C prefer-dynamic" cargo build
	cp util/src/trading/broker/shims/FXCM/native/target/debug/libfxcm.so dist/lib

	# build all modules and copy their binaries into the dist directory
	cd backtester && RUSTFLAGS="-L ../util/target/debug/deps -L ../dist/lib -C prefer-dynamic" cargo build
	cp backtester/target/debug/backtester dist
	cd spawner && RUSTFLAGS="-L ../util/target/debug/deps -L ../dist/lib -C prefer-dynamic" cargo build
	cp spawner/target/debug/spawner dist
	cd tick_parser && RUSTFLAGS="-L ../util/target/debug/deps -L ../dist/lib -C prefer-dynamic" cargo build
	cp tick_parser/target/debug/tick_processor dist
	cd optimizer && RUSTFLAGS="-L ../util/target/debug/deps -L ../dist/lib -C prefer-dynamic" cargo build
	cp optimizer/target/debug/optimizer dist
	cd logger && RUSTFLAGS="-L ../util/target/debug/deps -L ../dist/lib -C prefer-dynamic" cargo build
	cp logger/target/debug/logger dist
	cd mm && npm install
	cp ./mm dist -r
	cd private && RUSTFLAGS="-L ../util/target/debug/deps -L ../dist/lib -C prefer-dynamic" cargo build
	cp private/target/debug/libprivate.so dist/lib

	# build the FXCM native data downloader
	cd data_downloaders/fxcm_native && RUSTFLAGS="-L ../../util/target/debug/deps -L ../../dist/lib -C prefer-dynamic" cargo build
	cp data_downloaders/fxcm_native/target/debug/fxcm_native dist/fxcm_native_downloader

strip:
	cd dist && strip backtester spawner optimizer tick_processor
	cd dist/lib && strip *

clean:
	rm optimizer/target -rf
	rm logger/target -rf
	rm spawner/target -rf
	rm tick_parser/target -rf
	rm util/target -rf
	rm backtester/target -rf
	rm mm/node_modules -rf
	rm private/target -rf
	rm util/src/trading/broker/shims/FXCM/native/native/dist -rf
	rm util/src/trading/broker/shims/FXCM/native/target -rf
	rm data_downloaders/fxcm_native/target -rf
	rm configurator/target -rf

test:
	# build the bot's utility library and copy into dist/lib
	cd util && cargo build && cargo test --no-fail-fast
	cp util/target/debug/libalgobot_util.so dist/lib
	# copy libstd to the dist/lib directory
	cp $$(find $$(rustc --print sysroot)/lib | grep -E "libstd-.*\.so" | head -1) dist/lib

	# build the FXCM shim
	cd util/src/trading/broker/shims/FXCM/native/native && ./build.sh
	cp util/src/trading/broker/shims/FXCM/native/native/dist/* dist/lib
	cd util/src/trading/broker/shims/FXCM/native && RUSTFLAGS="-L ../../../../../../../util/target/debug/deps -L ../../../../../../../dist/lib -C prefer-dynamic" cargo build
	cp util/src/trading/broker/shims/FXCM/native/target/debug/libfxcm.so dist/lib

	cd optimizer && LD_LIBRARY_PATH="../dist/lib" RUSTFLAGS="-L ../util/target/debug/deps -L ../dist/lib -C prefer-dynamic" cargo test --no-fail-fast
	cd logger && LD_LIBRARY_PATH="../dist/lib" RUSTFLAGS="-L ../util/target/debug/deps -L ../dist/lib -C prefer-dynamic" cargo test --no-fail-fast
	cd spawner && LD_LIBRARY_PATH="../dist/lib" RUSTFLAGS="-L ../util/target/debug/deps -L ../dist/lib -C prefer-dynamic" cargo test --no-fail-fast

	cd tick_parser && LD_LIBRARY_PATH="../dist/lib" RUSTFLAGS="-L ../util/target/debug/deps -L ../dist/lib -C prefer-dynamic" cargo test --no-fail-fast
	cd backtester && LD_LIBRARY_PATH="../dist/lib" RUSTFLAGS="-L ../util/target/debug/deps -L ../dist/lib -C prefer-dynamic" cargo test --no-fail-fast
	cd mm && npm install
	cd private && LD_LIBRARY_PATH="../dist/lib" RUSTFLAGS="-L ../util/target/debug/deps -L ../dist/lib -C prefer-dynamic" cargo test --no-fail-fast
	cp private/target/release/libprivate.so dist/lib
	cd util/src/trading/broker/shims/FXCM/native && LD_LIBRARY_PATH=native/dist:../../../../../../target/debug/deps cargo test -- --nocapture
	cd data_downloaders/fxcm_native && LD_LIBRARY_PATH="../../dist/lib" RUSTFLAGS="-L ../../util/target/debug/deps -L ../../dist/lib -C prefer-dynamic" cargo test --no-fail-fast
	cd configurator && LD_LIBRARY_PATH="../../dist/lib" RUSTFLAGS="-L ../../util/target/debug/deps -L ../../dist/lib -C prefer-dynamic" cargo test --no-fail-fast
	# TODO: Collect the results into a nice format

bench:
	# build the bot's utility library and copy into dist/lib
	cd util && cargo build --release && cargo bench
	cp util/target/release/libalgobot_util.so dist/lib
	# copy libstd to the dist/lib directory
	cp $$(find $$(rustc --print sysroot)/lib | grep -E "libstd-.*\.so" | head -1) dist/lib

	# build all strategies and copy into dist/lib
	cd private && for dir in ./strategies/*/; \
	do \
		cd $$dir && cargo build --release && \
		cp target/release/lib$$(echo $$dir | sed 's/\.\/strategies\///; s/\///').so ../../../dist/lib && \
		cp target/release/lib$$(echo $$dir | sed 's/\.\/strategies\///; s/\///').so ../../../util/target/release/deps && \
		LD_LIBRARY_PATH="../../../dist/lib" cargo bench; \
	done

	cd optimizer && LD_LIBRARY_PATH="../dist/lib" cargo bench
	cd logger && LD_LIBRARY_PATH="../dist/lib" cargo bench
	cd spawner && LD_LIBRARY_PATH="../dist/lib" cargo bench
	cd tick_parser && LD_LIBRARY_PATH="../dist/lib" cargo bench
	cd backtester && LD_LIBRARY_PATH="../dist/lib" cargo bench
	cd mm && npm install
	cd private && LD_LIBRARY_PATH="../dist/lib" cargo bench
	cd configurator && LD_LIBRARY_PATH="../dist/lib" cargo bench
	# TODO: Collect the results into a nice format

update:
	cd optimizer && cargo update
	cd logger && cargo update
	cd spawner && cargo update

	# Build each strategy
	cd private && for dir in ./strategies/*/; \
	do \
		cd $$dir && cargo update; \
	done

	cd tick_parser && cargo update
	cd util && cargo update
	cd backtester && cargo update
	cd private && cargo update
	cd mm && npm update
	cd util/src/trading/broker/shims/FXCM/native && cargo update
	cd configurator && cargo update
	git submodule update

cdoc:
	cd optimizer && cargo rustdoc --open -- --no-defaults --passes collapse-docs --passes unindent-comments --passes strip-priv-imports
	cd logger && cargo rustdoc --open -- --no-defaults --passes collapse-docs --passes unindent-comments --passes strip-priv-imports
	cd spawner && cargo rustdoc --open -- --no-defaults --passes collapse-docs --passes unindent-comments --passes strip-priv-imports

	# Build each strategy
	cd private && for dir in ./strategies/*/; \
	do \
		cd $$dir && cargo rustdoc --open -- --no-defaults --passes collapse-docs --passes unindent-comments --passes strip-priv-imports; \
	done

	cd tick_parser && cargo rustdoc --open -- --no-defaults --passes collapse-docs --passes unindent-comments --passes strip-priv-imports
	cd util && cargo rustdoc --open -- --no-defaults --passes collapse-docs --passes unindent-comments --passes strip-priv-imports
	cd backtester && cargo rustdoc --open -- --no-defaults --passes collapse-docs --passes unindent-comments --passes strip-priv-imports
	cd configurator && cargo rustdoc --open -- --no-defaults --passes collapse-docs --passes unindent-comments --passes strip-priv-imports
	cd private && rustdoc --open -- --no-defaults --passes collapse-docs --passes unindent-comments --passes strip-priv-imports
	cd mm && npm install
	# TODO: Collect the results into a nice format

# kill off any straggler processes
kill:
	if [[ $$(ps -aux | grep '[t]arget/debug') ]]; then \
		kill $$(ps -aux | grep '[t]arget/debug' | awk '{print $$2}'); \
	fi
	if [[ $$(ps -aux | grep '[m]anager.js') ]]; then \
		kill $$(ps -aux | grep '[m]anager.js' | awk '{print $$2}'); \
	fi

configure:
	cd configurator && cargo run
	cp configurator/conf.rs util/src
	cp configurator/conf.js mm

config:
	make configure
