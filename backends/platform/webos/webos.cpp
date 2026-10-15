/* ScummVM - Graphic Adventure Engine
 *
 * ScummVM is the legal property of its developers, whose names
 * are too numerous to list here. Please refer to the COPYRIGHT
 * file distributed with this source distribution.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 *
 */

#include "backends/platform/webos/webos.h"
#include "backends/events/webossdl/webossdl-events.h"
#include "backends/keymapper/keymapper.h"

#include <PDL.h>

#if defined(WEBOS)

using namespace Common;

OSystem_SDL_WebOS::OSystem_SDL_WebOS()
	:
	OSystem_POSIX(),
	_keyboardVisible(false) {
}

/**
 * Initializes the backend.
 */
void OSystem_SDL_WebOS::initBackend() {
	// Create the events manager
	if (_eventSource == 0)
		_eventSource = new WebOSSdlEventSource();

	// Call parent implementation of this method
	OSystem_SDL::initBackend();
}

bool OSystem_SDL_WebOS::hasFeature(Feature f) {
	// The OS-supplied on-screen keyboard is only available from PDK 3.0
	// (HP TouchPad); older devices have a hardware keyboard.
	if (f == kFeatureVirtualKeyboard)
		return PDL_GetPDKVersion() >= 300;
	return OSystem_POSIX::hasFeature(f);
}

void OSystem_SDL_WebOS::setFeatureState(Feature f, bool enable) {
	if (f == kFeatureVirtualKeyboard) {
		if (PDL_GetPDKVersion() >= 300) {
			PDL_SetKeyboardState(enable ? PDL_TRUE : PDL_FALSE);
			_keyboardVisible = enable;
		}
		return;
	}
	OSystem_POSIX::setFeatureState(f, enable);
}

bool OSystem_SDL_WebOS::getFeatureState(Feature f) {
	if (f == kFeatureVirtualKeyboard)
		return _keyboardVisible;
	return OSystem_POSIX::getFeatureState(f);
}

#endif
