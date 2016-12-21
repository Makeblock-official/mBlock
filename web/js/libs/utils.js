/**
 * Flash常用数值转换函数
 */
var _app;
function FlashUtils(app){
    _app = app;
    var self = this;
    this.isArray = function(target){
        return Object.prototype.toString.call(target) == "[object Array]";
    }
    this.castDataView2Array = function(dataView){
        var n = dataView.byteLength;
        var result = new Array(n);
        for(var i=0; i<n; ++i)
            result[i] = dataView.getUint8(i);
        return result;
    }

    this.castArray2DataView = function(bytes){
        var n = bytes.length;
        var dataView = new DataView(new ArrayBuffer(n));
        for(var i=0; i<n; ++i)
            dataView.setUint8(i, bytes[i]);
        return dataView;
    }

    this.parseShort = function(bytes){
        if(bytes.length < 2)
            return 0;
        return self.castArray2DataView(bytes).getInt16(0, true);
    }

    this.parseInt32 = function(bytes){
        if(bytes.length < 4)
            return 0;
        return self.castArray2DataView(bytes).getInt32(0, true);
    }

    this.parseFloat32 = function(bytes){
        if(bytes.length < 4)
            return 0;
        return self.castArray2DataView(bytes).getFloat32(0, true);
    }

    this.parseDouble = function(bytes){
        return self.parseFloat32(bytes);
    }

    this.short2array = function(val){
        var dataView = new DataView(new ArrayBuffer(2));
        dataView.setInt16(0, val, true);
        return self.castDataView2Array(dataView);
    }

    this.int2array = function(val){
        var dataView = new DataView(new ArrayBuffer(4));
        dataView.setInt32(0, val, true);
        return self.castDataView2Array(dataView);
    }

    this.float2array = function(val){
        var dataView = new DataView(new ArrayBuffer(4));
        dataView.setFloat32(0, val, true);
        return self.castDataView2Array(dataView);
    }
    this.readFloat = function(arr,position){
		var f= [arr[position],arr[position+1],arr[position+2],arr[position+3]];
		return self.parseFloat32(f);
	}
	this.readInt = function(arr,position,count){
		var result = 0;
		for(var i=0; i<count; ++i){
			result |= arr[position+i] << (i << 3);
		}
		return result;
	}
	this.readDouble = function(arr,position){
		return self.readFloat(arr,position);
	}
	this.readString = function(arr,position,len){
		var value = "";
		for(var ii=0;ii<len;ii++){
			value += String.fromCharCode(_rxBuf[ii+position]);
		}
		return value;
	}
    this.appendBuffer = function( buffer1, buffer2 ) {
        return buffer1.concat( buffer2 );
    }
    const encoder = new TextEncoder('utf-8');
    const decoder = new TextDecoder('utf-8');

    this.string2array = function(val){
        var buffer = encoder.encode(val);//uint8 array
        var n = buffer.length;
        var result = new Array(n);
        for(var i=0; i<n; ++i)
            result[i] = buffer[i];
        return result;
    }

    this.array2string = function(bytes){
        var dataView = castArray2DataView(bytes);
        return decoder.decode(dataView);
    }

}
module.exports = FlashUtils;