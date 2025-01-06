/***************************************************/
/* Part of Bosca Ceoil Blue                        */
/* Copyright (c) 2025 Yuri Sizov and contributors  */
/* Provided under MIT                              */
/***************************************************/

const BOSCAWEB_STATE_INITIAL  = 0;
const BOSCAWEB_STATE_PROGRESS = 1;
const BOSCAWEB_STATE_READY    = 2;
const BOSCAWEB_STATE_FAILED   = 3;

// Can technically be configured with Module["INITIAL_MEMORY"], but we don't have
// access to that as early as we need it. It seems to be unset though, so using
// default should be safe.
const BOSCAWEB_INITIAL_MEMORY = 33554432;
const BOSCAWEB_MAXIMUM_MEMORY = 2147483648; // 2 GB
const BOSCAWEB_MEMORY_PAGE_SIZE = 65536;

const BOSCAWEB_COMPATIBILITY_OK = 0;
const BOSCAWEB_COMPATIBILITY_WARNING = 1;
const BOSCAWEB_COMPATIBILITY_FAILURE = 2;

class BoscaWeb {
	constructor() {
		this.initializing = true;
		this.engine = new Engine(GODOT_CONFIG);
		this._allocatedMemory = 0;
		this.memory = this._allocateWasmMemory();
		
		this._bootOverlay = document.getElementById('boot-overlay');
		this._boot_initialState = document.getElementById('boot-menu');
		this._boot_progressState = document.getElementById('boot-progress');
		this._boot_failedState = document.getElementById('boot-fatal-error');
		
		this._bootButton = document.getElementById('boot-init-button');
		this._bootButton.addEventListener('click', () => {
			this.init();
		});
		
		this._progressBar = document.getElementById('boot-progress-bar');
		this._progressStatus = document.getElementById('boot-progress-status');
		
		this._progressValues = {};
		for (const filename in BOSCA_FILE_SIZES) {
			this._progressValues[filename] = { 'total': BOSCA_FILE_SIZES[filename], 'loaded': 0 };
		}
		
		this._compat_passedState = document.getElementById('boot-compat-passed');
		this._compat_failedState = document.getElementById('boot-compat-failed');
		this._compat_failedHeaderError = document.getElementById('boot-compat-failed-error');
		this._compat_failedHeaderWarning = document.getElementById('boot-compat-failed-warning');
		this._compat_failedList = document.getElementById('boot-compat-list');
		this._compat_tryfixButton = document.getElementById('boot-compat-tryfix');
		this._compat_tryfixButton.addEventListener('click', () => {
			this.tryFixCompatibility();
		});
		
		this._compatLevel = BOSCAWEB_COMPATIBILITY_OK;
		this._compatFixable = (this.memory && GODOT_CONFIG['serviceWorker'] && GODOT_CONFIG['ensureCrossOriginIsolationHeaders'] && 'serviceWorker' in navigator);
		
		// Hidden by default to show native error messages, e.g. if JavaScript
		// is disabled in the browser.
		this._bootOverlay.style.visibility = 'visible';
		this.setState(BOSCAWEB_STATE_INITIAL);
	}
	
	_allocateWasmMemory() {
		// We will try to allocate as much as possible, starting with the limit that we actually require.
		// In Safari this is likely to fail, so we try less and less. This is not guaranteed to work, but
		// at least it gives user a chance.
		const reductionSteps = [ 1, 0.75, 0.5, 0.25 ];
		let reductionIndex = 0;
		
		let wasmMemory = null;
		let sizeMessage = '';
		while (wasmMemory == null && reductionIndex < reductionSteps.length) {
			const reduction = reductionSteps[reductionIndex];
			this._allocatedMemory = BOSCAWEB_MAXIMUM_MEMORY * reduction;
			sizeMessage = `${this._humanizeSize(BOSCAWEB_INITIAL_MEMORY)} out of ${this._humanizeSize(this._allocatedMemory)}`;
			
			// This can fail if we hit the browser's limit.
			try {
				wasmMemory = new WebAssembly.Memory({
					initial: BOSCAWEB_INITIAL_MEMORY / BOSCAWEB_MEMORY_PAGE_SIZE,
					maximum: reduction * BOSCAWEB_MAXIMUM_MEMORY / BOSCAWEB_MEMORY_PAGE_SIZE,
					shared: true
				});
			} catch (err) {
				console.error(err);
				wasmMemory = null;
			}
			
			reductionIndex += 1;
		}
		
		if (wasmMemory == null) {
			console.error(`Failed to allocate WebAssembly memory (${sizeMessage}); check the limits.`);
			return null;
		}
		if (!(wasmMemory.buffer instanceof SharedArrayBuffer)) {
			console.error(`Trying to allocate WebAssembly memory (${sizeMessage}), but returned buffer is not SharedArrayBuffer; this indicates that threading is probably not supported.`);
			return null;
		}
		
		console.log(`Successfully allocated WebAssembly memory (${sizeMessage}).`);
		return wasmMemory;
	}
	
	_checkMissingFeatures() {
		const missingFeatures = Engine.getMissingFeatures({
			threads: GODOT_THREADS_ENABLED,
		});
		
		return missingFeatures.map((item) => {
			const itemParts = item.split(' - ');
			return {
				'name': itemParts[0],
				'description': itemParts[1] || '',
			}
		});
	}
	
	checkCompatibility() {
		this._bootButton.classList.remove('boot-init-suppressed');
		this._compat_passedState.style.display = 'none';
		this._compat_failedState.style.display = 'none';
		this._compat_failedHeaderError.style.display = 'none';
		this._compat_failedHeaderWarning.style.display = 'none';
		this._compat_tryfixButton.style.display = 'none';
		this._compat_failedList.style.display = 'none';
		this._setErrorText(this._compat_failedList, '');
		
		this._compatLevel = BOSCAWEB_COMPATIBILITY_OK;
		
		// Check memory allocation.
		if (this.memory == null) {
			this._lowerCompatibilityLevel(BOSCAWEB_COMPATIBILITY_FAILURE);
			this._addCompatibilityLevelReason('Your browser does not allow enough memory');
			
			const reasonDescription = document.createElement('span');
			reasonDescription.textContent = `Bosca requested maximum limit of ${this._humanizeSize(BOSCAWEB_MAXIMUM_MEMORY)}, but was refused.`;
			this._compat_failedList.appendChild(reasonDescription);
		}
		else if (this._allocatedMemory < BOSCAWEB_MAXIMUM_MEMORY) {
			this._lowerCompatibilityLevel(BOSCAWEB_COMPATIBILITY_WARNING);
			this._addCompatibilityLevelReason('Your browser does not allow enough memory');
			
			const reasonDescription = document.createElement('span');
			reasonDescription.textContent = `Bosca requested maximum limit of ${this._humanizeSize(BOSCAWEB_MAXIMUM_MEMORY)}, but was only allowed ${this._humanizeSize(this._allocatedMemory)}.`;
			this._compat_failedList.appendChild(reasonDescription);
		}
		
		// Check for missing browser feature.
		const missingFeatures = this._checkMissingFeatures();
		if (missingFeatures.length > 0) {
			this._lowerCompatibilityLevel(BOSCAWEB_COMPATIBILITY_FAILURE);
			this._addCompatibilityLevelReason('Your browser is missing following features');
			
			const reasonDescription = document.createElement('span');
			this._compat_failedList.appendChild(reasonDescription);
			missingFeatures.forEach((item, index) => {
				const annotatedElement = document.createElement('abbr');
				annotatedElement.textContent = item.name;
				annotatedElement.title = item.description;
				reasonDescription.appendChild(annotatedElement);
				
				if (index < missingFeatures.length - 1) {
					reasonDescription.appendChild(document.createTextNode(", "));
				}
			});
		}
		
		switch (this._compatLevel) {
			case BOSCAWEB_COMPATIBILITY_OK:
				this._compat_passedState.style.display = 'flex';
				break;
			
			case BOSCAWEB_COMPATIBILITY_WARNING:
				this._bootButton.classList.add('boot-init-suppressed');
				this._compat_failedState.style.display = 'flex';
				this._compat_failedHeaderWarning.style.display = 'inline-block';
				this._compat_failedList.style.display = 'block';
				this._compat_tryfixButton.style.display = (this._compatFixable ? 'inline-block' : 'none');
				break;
			
			case BOSCAWEB_COMPATIBILITY_FAILURE:
				this._bootButton.classList.add('boot-init-suppressed');
				this._compat_failedState.style.display = 'flex';
				this._compat_failedHeaderError.style.display = 'inline-block';
				this._compat_failedList.style.display = 'block';
				this._compat_tryfixButton.style.display = (this._compatFixable ? 'inline-block' : 'none');
				break;
		}
	}
	
	_addCompatibilityLevelReason(message) {
		if (this._compat_failedList.hasChildNodes()) {
			this._compat_failedList.appendChild(document.createElement('br'));
		}
		
		const reasonHeader = document.createElement('strong');
		reasonHeader.textContent = `${message}: `;
		this._compat_failedList.appendChild(reasonHeader);
	}
	
	_lowerCompatibilityLevel(level) {
		if (this._compatLevel < level) {
			this._compatLevel = level;
		}
	}
	
	async tryFixCompatibility() {
		if (!this._compatFixable) {
			return;
		}
		
		// There's a chance that installing the service worker will fix the issue.
		// Taken from Godot sources, see full-size.html for the up-to-date version.
		
		try {
			await Promise.race([
				navigator.serviceWorker.getRegistration()
					.then((registration) => {
						if (registration != null) {
							return Promise.reject(new Error('Service worker already exists.'));
						}
						return registration;
					})
					.then(() => this.engine.installServiceWorker()),
				
				// For some reason, `getRegistration()` can stall.
				new Promise((resolve) => {
					setTimeout(() => resolve(), 2000);
				}),
			]);
		} catch (err) {
			console.error('Error while registering service worker:', err);
		}
		
		// FIXME: This can potentially reload-loop indefinitely, which isn't great.
		window.location.reload();
	}
	
	async init() {
		this._updateBootProgress();
		this.setState(BOSCAWEB_STATE_PROGRESS);
		
		try {
			await this.engine.startGame();
			this.setState(BOSCAWEB_STATE_READY);
		} catch (err) {
			this._fatalError(err);
		}
	}
	
	setState(mode) {
		if (this.state === mode || !this.initializing) {
			return;
		}
		this.state = mode;
		
		if (this.state === BOSCAWEB_STATE_READY) {
			this._bootOverlay.remove();
			this.initializing = false;
			return;
		}
		
		this._boot_initialState.style.display  = (this.state === BOSCAWEB_STATE_INITIAL  ? 'flex'  : 'none');
		this._boot_progressState.style.display = (this.state === BOSCAWEB_STATE_PROGRESS ? 'flex' : 'none');
		this._boot_failedState.style.display   = (this.state === BOSCAWEB_STATE_FAILED   ? 'block' : 'none');
	}
	
	setLoadingProgress(file, loadedSize) {
		this._progressValues[file].loaded = loadedSize;
		requestAnimationFrame(this._updateBootProgress.bind(this));
	}
	
	_updateBootProgress() {
		let total = Object.values(this._progressValues).reduce((sum, val) => sum + val.total, 0);
		let loaded = Object.values(this._progressValues).reduce((sum, val) => sum + val.loaded, 0);
		
		if (loaded > 0 && total > 0) {
			this._progressBar.value = loaded;
			this._progressBar.max = total;
			
			if (loaded >= total) {
				this._progressStatus.textContent = "Launching, it may take a moment...";
			}
		} else {
			this._progressBar.removeAttribute('value');
			this._progressBar.removeAttribute('max');
		}
	}
	
	_setErrorText(element, text) {
		while (element.lastChild) {
			element.removeChild(element.lastChild);
		}
		
		if (text === '') {
			return;
		}
		
		const lines = text.split('\n');
		lines.forEach((line) => {
			element.appendChild(document.createTextNode(line));
			element.appendChild(document.createElement('br'));
		});
	}
	
	_fatalError(err) {
		console.error(err);
		
		if (err instanceof Error) {
			this._setErrorText(this._boot_failedState, err.message);
		} else if (typeof err === 'string') {
			this._setErrorText(this._boot_failedState, err);
		} else {
			this._setErrorText(this._boot_failedState, 'An unknown error occurred.');
		}
		
		this.setState(BOSCAWEB_STATE_FAILED);
		this.initializing = false;
	}
	
	_humanizeSize(size) {
		const labels = [ 'B', 'KB', 'MB', 'GB', 'TB', ];
		
		let label = labels[0];
		let value = size;
		
		let index = 0;
		while (value >= 1024 && index < labels.length) {
			index += 1;
			value = value / 1024;
			label = labels[index];
		}
		
		return `${value.toFixed(2)} ${label}`;
	}
}
