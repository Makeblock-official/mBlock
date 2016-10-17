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
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.EventDispatcher;
	import flash.geom.Rectangle;
	public class ObjectDetector extends EventDispatcher{
		private var tgt       :TargetImage;
		public  var detected  :Array;	// of Rectangles
		public  var cascade   :HaarCascade;
		private var _options  :ObjectDetectorOptions;
		
		public function ObjectDetector() {
			tgt = new TargetImage();
			cascade = new HaarCascade();
		}

		public function detect( bmp:BitmapData ) :void{
			if ( bmp  ) {
				tgt.bitmapData = bmp;
			}

			dispatchEvent( new ObjectDetectorEvent(ObjectDetectorEvent.DETECTION_START) );
			_detect();
		}

		private function _detect() :void {

			cascade.targetImage = tgt;
			
			detected = [];
			var imgw :int = tgt.width, imgh :int = tgt.height;
			var scaledw :int, scaledh :int, limitx  :int, limity  :int, stepx :int, stepy :int, result :int, factor:Number = 1;
			var checkRect:Rectangle = new Rectangle();
			
			for( factor = 1;
				factor * cascade.base_window_w < imgw && factor * cascade.base_window_h < imgh;
				factor *= _options.scale_factor )
			{
				checkRect.width = scaledw = int( cascade.base_window_w * factor );
				checkRect.height = scaledh = int( cascade.base_window_h * factor );
				if( scaledw < _options.min_size || scaledh < _options.min_size ){
					continue;
				}
				limitx = tgt.width  - scaledw;
				limity = tgt.height - scaledh;
				if( _options.endx != ObjectDetectorOptions.INVALID_POS && _options.endy != ObjectDetectorOptions.INVALID_POS ){
					limitx = ( _options.endx < limitx ? _options.endx : limitx);
					limity = ( _options.endy < limity ? _options.endy : limity);
				}
				//logger("[detect]limitx,y: "+limitx+","+limity);

				//stepx  = Math.max(_options.MIN_MARGIN_SEARCH,factor);
				stepx  = scaledw >> 3;
				stepy  = stepx;
				//logger("[detect] w,h,step: "+scaledw+","+scaledh+","+stepx);

				var ix:int=0, iy:int=0, startx:int=0, starty:int=0;
				if( _options.startx != ObjectDetectorOptions.INVALID_POS && _options.starty != ObjectDetectorOptions.INVALID_POS ){
					startx = ( ix > _options.startx ? ix : _options.startx);
					starty = ( iy > _options.starty ? iy : _options.starty);
				}
				//logger("[detect]startx,y: "+startx+","+starty);
				cascade.scale = factor;
				
				for( iy = starty; iy < limity; iy += stepy )
				{
					checkRect.y = iy;
					for( ix = startx; ix < limitx; ix += stepx )
					{
						checkRect.x = ix;
						if( !( (_options.search_mode & ObjectDetectorOptions.SEARCH_MODE_NO_OVERLAP ) &&
							overlaps(checkRect)) ){
							
							//logger("[checkAndRun]ix,iy,scaledw,scaledh: "+ix+","+iy+","+scaledw+","+scaledh);
							
							result = cascade.run(checkRect);
							if ( result > 0 ) {
								//var faceArea :Rectangle = checkRect.clone();
								detected.push( checkRect.clone() );
								//logger("[createCheckAndRun]found!: "+ix+","+iy+","+scaledw+","+scaledh);

								// doesnt mean anything cause detection is not time-divided (now)
								/*
								var ev1 :ObjectDetectorEvent = new ObjectDetectorEvent( ObjectDetectorEvent.FACE_FOUND );
								ev1.rect = faceArea;
								dispatchEvent( ev1 );
								*/
							}
						}
					}
				}
			}

			// integrate redundant candidates ...

			var ev2 :ObjectDetectorEvent = new ObjectDetectorEvent( ObjectDetectorEvent.DETECTION_COMPLETE );
			ev2.rects = detected;
			dispatchEvent( ev2 );
		}

		private function overlaps( rect:Rectangle):Boolean
		{
			// if the area we're going to check contains, or overlaps the square which is already picked up, ignore it
			for each ( var r:Rectangle in detected )
			{
				if ( rect.intersects( r )) return true;
			}
			return false;
		}

		public function set bitmap( bmp :Bitmap ) :void {
			tgt.bitmapData = bmp.bitmapData;
		}
		public function set options( opt :ObjectDetectorOptions ) :void {
			_options = opt;
		}

	}
}
