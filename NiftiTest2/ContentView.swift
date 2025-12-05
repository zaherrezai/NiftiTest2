//
//  ContentView.swift
//  NiftiTest2
//
//  Created by Zaher Rezai on 02/12/2025.
//

import Gzip
import SwiftUI
internal import Combine

struct ContentView: View {
	@EnvironmentObject var VM : viewModel
	@State var currentLayer: Double = 0.0

	var body: some View {
		VStack{
			ZStack{
				Color.blue.ignoresSafeArea()
				if VM.globalVolum.count > 0{
					LayerViewZ(volum: VM.globalVolum, z: Int(currentLayer))
				}
				
			}
			.frame(width: 260, height: 260)
			Button{
				VM.DownloadNifti()
			}label: {
				Text("Download nifti file ")
					.frame(width: 200, height: 20)
					.foregroundColor(.white)
					.background(Color.blue)
					.cornerRadius(20)
			}
			if VM.globalVolum.count > 0 {
				Slider(value: $currentLayer, in: 0...Double(VM.globalVolum.count - 1), step: 1)
			}
		}
		
	}
}

#Preview {
	ContentView()
}

class viewModel : ObservableObject{
	
	@Published var globalVolum : [[[Float]]] = []
	
	func DownloadNifti() {
		guard let url = URL(string: "https://github.com/neurolabusc/niivue-images/raw/refs/heads/main/CT_Abdo.nii.gz") else {
			print("invalid url")
			return
		}
		URLSession.shared.downloadTask(with: url){localurl,Response,error in
			if let error = error {
				print("error", error)
				return
			}
			if let response = Response as? HTTPURLResponse {
				print("response",response.statusCode)
				
			}
			guard let localurl = localurl else {
				print("no file")
				return
			}
			self.Decompression(localurl: localurl, url: url)
			print("file downloaded",localurl)
		}.resume()
		
	}
	
	func Decompression (localurl : URL, url : URL){
		let filenamegz : String = url.lastPathComponent
		let fileName : String = filenamegz.replacingOccurrences(of: ".gz", with: "")
		let ducPathUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
		let saveUrl = ducPathUrl.appendingPathComponent(fileName)
		let fdata = try! Data(contentsOf: localurl)
		var decompressedData: Data
		if fdata.isGzipped {
			decompressedData = try! fdata.gunzipped()
			print("decompressed")
			if ((try? decompressedData.write(to: saveUrl)) != nil){
				print("saved at :\(saveUrl)")
			}
		} else {
			decompressedData = fdata
		}
		ExtractHeaderAndDataFromNifti(decompressed: decompressedData)
	}
	func ExtractHeaderAndDataFromNifti(decompressed: Data){
		
		let rawData : Data = decompressed
		let header = rawData.prefix(348)
		//let datatype = Int(readInt16(header, offset: 70))
		let dim1 = Int(readInt16(header, offset: 42))
		let dim2 = Int(readInt16(header, offset: 44))
		let dim3 = Int(readInt16(header, offset: 46))
		let voxel = Int(readfloat32(header, offset: 108))
		let voxelOffset = Int(voxel)
		var result: [[[Float]]] = []
		result = CreateVolumForX(data: rawData, dim1: Int(dim1), dim2: Int(dim2), dim3: Int(dim3), voxelOfsset: voxelOffset)
		DispatchQueue.main.async {
			self.globalVolum = result
		}
		//print(voxel)
	}
	
	
	func CreateVolumForZ (data : Data ,
					  dim1 : Int ,
					  dim2 : Int ,
					  dim3 : Int ,
					  voxelOfsset : Int ) -> [[[Float]]]{
		var volum =
		Array(repeating: Array(
			repeating: Array(
				repeating: Float(0.0),
				count: dim1),
			count: dim2),
			  count: dim3)
		print("volum created")
		var currentIndex = voxelOfsset
		for z in 0..<dim3 {
			for y in 0..<dim2 {
				for x in 0..<dim1{
					if currentIndex < data.count{
						let binaryValue = data[currentIndex]
						let lighness = Float(binaryValue) / 255
						volum[z][y][x] = Float(lighness)
						currentIndex += 1
					}
				}
			}
		}
		return volum
	}
	func CreateVolumForX (data : Data ,
					  dim1 : Int ,
					  dim2 : Int ,
					  dim3 : Int ,
					  voxelOfsset : Int ) -> [[[Float]]]{
		var volum =
		Array(repeating: Array(
			repeating: Array(
				repeating: Float(0.0),
				count: dim3),
			count: dim2),
			  count: dim1)
		print("volum created")
		var currentIndex = voxelOfsset
		for z in 0..<dim3 {
			for y in 0..<dim2 {
				for x in 0..<dim1{
					if currentIndex < data.count{
						let binaryValue = data[currentIndex]
						let lighness = Float(binaryValue) / 255
						volum[x][y][z] = Float(lighness)
						currentIndex += 1
					}
				}
			}
		}
		return volum
	}
	
	
	func CreateVolumForY (data : Data ,
					  dim1 : Int ,
					  dim2 : Int ,
					  dim3 : Int ,
					  voxelOfsset : Int ) -> [[[Float]]]{
		var volum =
		Array(repeating: Array(
			repeating: Array(
				repeating: Float(0.0),
				count: dim3),
			count: dim1),
			  count: dim2)
		print("volum created")
		var currentIndex = voxelOfsset
		for z in 0..<dim3 {
			for y in 0..<dim2 {
				for x in 0..<dim1{
					if currentIndex < data.count{
						let binaryValue = data[currentIndex]
						let lighness = Float(binaryValue) / 255
						volum[y][x][z] = Float(lighness)
						currentIndex += 1
					}
				}
			}
		}
		return volum
	}
	
	
	
	func readInt16(_ data : Data , offset : Int) -> Int16 {
		let byte1 = UInt16(data[offset])
		let byte2 = UInt16(data[offset + 1]) << 8
		return Int16(byte1 | byte2)
	}
	
	func readInt8(_ data : Data , offset : Int) -> Int8 {
		let byte1 = UInt8(data[offset])
		return Int8(byte1 )
	}
	
	func readfloat32(_ data : Data , offset : Int) -> Float32 {
		let byte1 = UInt32(data[offset])
		let byte2 = UInt32(data[offset + 1]) << 8
		let byte3 = UInt32(data[offset + 2]) << 16
		let byte4 = UInt32(data[offset + 3]) << 24
		let value = byte1 | byte2 | byte3 | byte4
		return Float32(bitPattern: value)
	}


	
	
}
struct LayerViewX : View{
	@EnvironmentObject var VM : viewModel
	let volum : [[[Float]]]
	let x : Int
	var body : some View {
		let layer = volum[x]
		VStack(spacing: 0){
			ForEach(0..<layer.count, id: \.self){y in
				HStack(spacing: 0){
					ForEach(0..<layer[y].count, id: \.self){ z in
						Pixel(light: layer[y][z])
					}
				}
			}
		}
	}
}
struct LayerViewY : View{
	@EnvironmentObject var VM : viewModel
	let volum : [[[Float]]]
	let y : Int
	var body : some View {
		let layer = volum[y]
		VStack(spacing: 0){
			ForEach(0..<layer.count, id: \.self){x in
				HStack(spacing: 0){
					ForEach(0..<layer[x].count, id: \.self){ z in
						Pixel(light: layer[x][z])
					}
				}
			}
		}
	}
}
struct LayerViewZ : View{
	@EnvironmentObject var VM : viewModel
	let volum : [[[Float]]]
	let z : Int
	var body : some View {
		let layer = volum[z]
		VStack(spacing: 0){
			ForEach(0..<layer.count, id: \.self){y in
				HStack(spacing: 0){
					ForEach(0..<layer[y].count, id: \.self){ x in
						Pixel(light: layer[y][x])
					}
				}
			}
		}
	}
}
struct Pixel: View {
	@EnvironmentObject var VM : viewModel
	let light: Float
	var body: some View {
		Rectangle()
			.fill(Color(white : Double(light)))
			.frame(width: 1, height: 1)
	}
}


//func indextoxyz(index: Int, dimx: Int, dimy: Int, dimz: Int ) ->(x: Int, y: Int ,z: Int){
//	   let z = index / (dimx * dimy)
//	   let rest = index % (dimx * dimy)
//	   let y = rest / dimx
//	   let x = rest % dimx
//	   return (x, y, z)
//   }
//   func printVoxel(from start: Int, count howmany: Int , volum : [[[Float]]]) {
//	   let dimz = volum.count
//	   let dimy = volum[0].count
//	   let dimx = volum[0][0].count
//	   let total = dimx * dimy * dimz
//	   let endIndex = min(start + howmany , total)
//	   for index in start..<endIndex {
//		   let coord = indextoxyz(index: index, dimx: dimx, dimy: dimy, dimz: dimz)
//		   let value = volum[coord.z][coord.y][coord.x]
//		   print("\(index) -> (\(coord.z),\(coord.y),\(coord.x) = \(value)")
//	   }
//   }
