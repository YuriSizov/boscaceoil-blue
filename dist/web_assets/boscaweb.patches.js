/***************************************************/
/* Part of Bosca Ceoil Blue                        */
/* Copyright (c) 2025 Yuri Sizov and contributors  */
/* Provided under MIT                              */
/***************************************************/

// Monkey-patch fetch to intercept Godot loading its bits and pieces.
(function(window){
	const _orig_fetch = window.fetch;
	window.fetch = async function(resource, options) {
		if (!(resource in BOSCA_FILE_SIZES)) {
			return await _orig_fetch(resource, options);
		}
		
		const response = await _orig_fetch(resource, options);
		const innerStream = new ReadableStream(
			{
				async start(controller) {
					const totalBytes = BOSCA_FILE_SIZES[resource];
					let loadedBytes = 0;
					
					const reader = response.body.getReader();
					
					while (true) {
						const { value, done } = await reader.read();
						if (done) {
							bosca.setLoadingProgress(resource, totalBytes);
							break;
						}
						
						loadedBytes += value.byteLength
						bosca.setLoadingProgress(resource, loadedBytes);
						controller.enqueue(value);
					}
					
					reader.releaseLock();
					controller.close();
				}
			},
			{
				status: response.status,
				statusText: response.statusText
			}
		)
		
		const forwardedResponse = new Response(innerStream);
		for (const pair of response.headers.entries()) {
			forwardedResponse.headers.set(pair[0], pair[1]);
		}
		
		return forwardedResponse;
	}
})(window);

// Monkey-patch the Godot initializer to influence initialization where it cannot be configured.
(function(window){
	const _orig_Godot = window.Godot;
	
	window.Godot = function(Module) {
		// Use a pre-allocated buffer that uses a safer amount of maximum memory, which
		// avoids instant crashes in Safari. Although, there can still be memory issues
		// in Safari (both macOS and iOS/iPadOS), with some indication of improvements
		// starting with Safari 18.
		if (window.bosca.memory != null) {
			Module["wasmMemory"] = window.bosca.memory;
		}
		
		// The initializer can still throw exceptions, including an out of memory exception.
		// Due to nested levels of async and promise handling, this is not captured by
		// try-catching Engine.startGame(). But it can be captured here.
		try {
			return _orig_Godot(Module);
		} catch (err) {
			window.bosca._fatalError(err);
		}
	}
})(window);
