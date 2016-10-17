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
	public final class HaarRect{
		public  var dx      :int;	// default values read from xml
		public  var dy      :int;
		public  var dw      :int;
		public  var dh      :int;
		public  var dweight :Number;
		public  var sx      :int;	// scaled values
		public  var sy      :int;
		public  var sw      :int;
		public  var sh      :int;
		public  var sweight :Number;
		
		public function HaarRect( d:Array ) 
		{
			dx      = d[0];
			dy      = d[1];
			dw      = d[2];
			dh      = d[3];
			dweight = d[4];
		}

		public function get area():int{
			return sw*sh;
		}

		public function set scale(s:Number):void
		{
			sx = int( dx * s );
			sy = int( dy * s );
			sw = int( dw * s );
			sh = int( dh * s );
		}

		public function set scale_weight(s:Number):void
		{
			sweight = dweight * s;
		}
		
	}
}
