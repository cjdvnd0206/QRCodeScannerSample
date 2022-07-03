//
//  QRScanManager.swift
//  QRCodeScannerSample
//
//  Created by 윤병진 on 2022/07/03.
//  QR코드 스캔관련 모듈, 사이즈 및 스캔인식간격 조절 가능

import UIKit
import AVFoundation

protocol QRScanManagerDelegate: AnyObject {
    // 스캔한 값을 output
    func scanOutput(code: String)
}

final class QRScanManager: NSObject, ObservableObject, DatetimeLogManager {
    weak var delegate: QRScanManagerDelegate?
    private var session = AVCaptureSession()
    private var previewLayer = AVCaptureVideoPreviewLayer()
    private let output = AVCaptureMetadataOutput()
    private var lastTime = Date(timeIntervalSince1970: 0)
    private var scanInterval: Double = 0.0
    public let qrCodeSquareSize: CGFloat = 200
    
    // view를 그린다
    public func scanForQRImage(previewIn previewContainer: UIView,
                               scanInterval: Double = 1,
                               offsetY: CGFloat = 0) {
        
        self.scanInterval = scanInterval
        
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            session.addInput(input)
        } catch {
            // 카메라를 사용할 수 없는 환경
            return
        }
        
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        session.addOutput(output)
        output.metadataObjectTypes = [.qr]
        
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewContainer.layer.addSublayer(previewLayer)
        previewLayer.frame = previewContainer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        
        // QR스캔영역 지정
        let rectOfInterest = CGRect(x: previewContainer.bounds.midX - (qrCodeSquareSize/2),
                                    y: previewContainer.bounds.midY - (qrCodeSquareSize/2 + offsetY),
                                    width: qrCodeSquareSize,
                                    height: qrCodeSquareSize)
        let aroundLayer = rectOfInterest.makeAroundLayer
        
        output.rectOfInterest = previewLayer.metadataOutputRectConverted(fromLayerRect: rectOfInterest)
        
        previewContainer.addSubview(aroundLayer)
    }
    
    public func startSession() {
        // 카메라 동작 사직
        datetimeLog("Session Start...")
        if !session.isRunning {
            session.startRunning()
        }
    }
    
    public func stopSession() {
        // 카메라 동작 중지
        datetimeLog("Session Stop...")
        if session.isRunning {
            session.stopRunning()
        }
    }
}

extension QRScanManager: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ captureOutput: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        for case let metadata as AVMetadataMachineReadableCodeObject in metadataObjects {
            if metadata.type == .qr {
                // 코드가 QR코드 타입일때만
                if let code = metadata.stringValue {
                    // 코드가 String 타입일때만
                    if Date().timeIntervalSince(lastTime) >= scanInterval {
                        // 스캔이 할 경우 딜레이 시간 설정
                        lastTime = Date()
                        delegate?.scanOutput(code: code)
                    }
                }
            }
        }
    }
}

protocol DatetimeLogManager {
    func datetimeLog(_ comment: String, _ function: String)
}
extension DatetimeLogManager {
    func datetimeLog(_ comment: String, _ function: String = #function) {
#if DEBUG
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
        print("\(dateFormatter.string(from: Date())) [\(function)] - \(comment)")
#endif
    }
}

extension CGRect {
    var makeAroundLayer: UIView {
        let whiteView = UIView(frame: UIScreen.main.bounds)
        let maskLayer = CAShapeLayer()
        let path = UIBezierPath(rect: whiteView.bounds)
        
        path.append(UIBezierPath(roundedRect: self, cornerRadius: 0))
        maskLayer.path = path.cgPath
        maskLayer.fillRule = .evenOdd
        whiteView.layer.mask = maskLayer
        whiteView.clipsToBounds = true
        whiteView.alpha = 0.7
        whiteView.backgroundColor = .black
        
        return whiteView
    }
}
