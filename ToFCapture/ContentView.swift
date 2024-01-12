//  ViewController.swift
//  ToFCapture
//
//  Created by Иван Романенко on 12.01.2024.
//

import UIKit
import AVFoundation
 
class ViewController: UIViewController, AVCaptureDepthDataOutputDelegate {

  var captureDevice: AVCaptureDevice!
  var captureSession: AVCaptureSession!
  var previewLayer: AVCaptureVideoPreviewLayer!

  var depthDataOutput: AVCaptureDepthDataOutput!

  var lastDepthImage: UIImage?

  override func viewDidLoad() {
    super.viewDidLoad()

    captureSession = AVCaptureSession()
    captureSession.sessionPreset = .photo

    guard let device = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) else {
      print("Нет доступа к задней камере")
      return
    }
    captureDevice = device

    do {
      let input = try AVCaptureDeviceInput(device: captureDevice)
      captureSession.addInput(input)
    } catch {
      print("Ошибка при добавлении входа камеры: \(error.localizedDescription)")
      return
    }

    previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    previewLayer.videoGravity = .resizeAspectFill
    previewLayer.frame = view.bounds
    view.layer.addSublayer(previewLayer)

    depthDataOutput = AVCaptureDepthDataOutput()
    depthDataOutput.setDelegate(self, callbackQueue: DispatchQueue(label: "depth data queue"))
    depthDataOutput.isFilteringEnabled = true

    guard captureSession.canAddOutput(depthDataOutput) else {
      print("Невозможно добавить вывод данных глубины в сессию")
      return
    }
    captureSession.addOutput(depthDataOutput)

    guard let connection = depthDataOutput.connection(with: .depthData) else {
      print("Нет соединения с данными глубины")
      return
    }
    connection.videoOrientation = .portrait

    captureSession.startRunning()
  }

  func depthDataOutput(_ output: AVCaptureDepthDataOutput, didOutput depthData: AVDepthData, timestamp: CMTime, connection: AVCaptureConnection) {

    let depthMap = depthData.depthDataMap

    let depthImage = CIImage(cvPixelBuffer: depthMap)

    let filter = CIFilter(name: "CIColorControls")
    filter?.setValue(depthImage, forKey: kCIInputImageKey)
    filter?.setValue(1.5, forKey: kCIInputContrastKey)
    let enhancedDepthImage = filter?.outputImage

    let context = CIContext()
    if let image = enhancedDepthImage, let cgImage = context.createCGImage(image, from: image.extent) {
      let uiImage = UIImage(cgImage: cgImage)
      lastDepthImage = uiImage
    }
  }

  @IBAction func saveDepthImage(_ sender: Any) {
    // Проверяем, есть ли изображение глубины
    guard let image = lastDepthImage else {
      print("Нет изображения глубины для сохранения")
      return
    }
    UIImageWriteToSavedPhotosAlbum(image, self, #selector(imageSaved(_:didFinishSavingWithError:contextInfo:)), nil)
  }
  @objc func imageSaved(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
    if let error = error {
      print("Ошибка при сохранении изображения глубины: \(error.localizedDescription)")
    } else {
      print("Изображение глубины успешно сохранено")
    }
  }
}

//  ViewControllerRepresentable.swift
//  ToFCapture
//
//  Created by Иван Романенко on 12.01.2024.
//

import SwiftUI

struct ViewControllerRepresentable: UIViewControllerRepresentable {

  func makeUIViewController(context: Context) -> ViewController {
    return ViewController()
  }

  func updateUIViewController(_ uiViewController: ViewController, context: Context) {
    // do nothing
  }
}

//  ContentView.swift
//  ToFCapture
//
//  Created by Иван Романенко on 12.01.2024.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ViewControllerRepresentable()
    }
}

#Preview {
    ContentView()
}

