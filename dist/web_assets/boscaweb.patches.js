/***************************************************/
/* Part of Bosca Ceoil Blue                        */
/* Copyright (c) 2024 Yuri Sizov and contributors  */
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
							bosca.setLoadingProgress(resource, (totalBytes - loadedBytes));
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
