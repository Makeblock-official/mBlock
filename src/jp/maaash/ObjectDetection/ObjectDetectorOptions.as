//
// Project Marilena
// Object Detection in Actionscript3
// based on OpenCV (Open Computer Vision Library) Object Detection
//
// Copyright (C) 2008, Masakazu OHTSUKA (mash), all rights reserved.
// contact o.masakazu(at)gmail.com
//
// additional optimizations by Mario Klingemann / Quasimondo
// contact mario(at)quasimondo.com
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
//   * Redistribution's of source code must retain the above copyright notice,
//     this list of conditions and the following disclaimer.
//
//   * Redistribution's in binary form must reproduce the above copyright notice,
//     this list of conditions and the following disclaimer in the documentation
//     and/or other materials provided with the distribution.
//
// This software is provided by the copyright holders and contributors "as is" and
// any express or implied warranties, including, but not limited to, the implied
// warranties of merchantability and fitness for a particular purpose are disclaimed.
// In no event shall the Intel Corporation or contributors be liable for any direct,
// indirect, incidental, special, exemplary, or consequential damages
// (including, but not limited to, procurement of substitute goods or services;
// loss of use, data, or profits; or business interruption) however caused
// and on any theory of liability, whether in contract, strict liability,
// or tort (including negligence or otherwise) arising in any way out of
// the use of this software, even if advised of the possibility of such damage.
//
package jp.maaash.ObjectDetection
{
	public class ObjectDetectorOptions{
		public static const SCALE_FACTOR      :Number = 1.2;
		public static const MIN_SIZE          :int    = 15;
		public static const MIN_MARGIN_SEARCH :int = 3;

		public static const SEARCH_MODE_DEFAULT    :int = 0;
		public static const SEARCH_MODE_SOLO       :int = 1;
		public static const SEARCH_MODE_NO_OVERLAP :int = 2;

		public static const INVALID_POS            :int = -1;

		//public static const search_mode   :int = SEARCH_MODE_DEFAULT;
		//public static const search_mode   :int = SEARCH_MODE_SOLO;
		public var search_mode :int    = SEARCH_MODE_NO_OVERLAP;	// about 50% speed up
		public var scale_factor:Number = SCALE_FACTOR;
		public var min_size    :int    = MIN_SIZE;
		public var startx      :int    = INVALID_POS;
		public var starty      :int    = INVALID_POS;
		public var endx        :int    = INVALID_POS;
		public var endy        :int    = INVALID_POS;
	}
}
