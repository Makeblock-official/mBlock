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
	import flash.events.Event;
	import flash.geom.Rectangle;
	public class ObjectDetectorEvent extends Event {
		public static const DETECTION_COMPLETE         :String = "ObjectDetectorEvent_DETECTION_COMPLETE";
		public static const FACE_FOUND                 :String = "ObjectDetectorEvent_FACE_FOUND";
		public static const DETECTION_START            :String = "ObjectDetectorEvent_DETECTION_START";

		public var rect         :Rectangle;
		public var rects        :Array;
		public function ObjectDetectorEvent( t :String ) {
			super(t);
		}
		public override function clone():Event {
			var ev :ObjectDetectorEvent = new ObjectDetectorEvent( type );
			ev.rect  = rect;
			ev.rects = rects;
			return ev;
		}
	}
}
