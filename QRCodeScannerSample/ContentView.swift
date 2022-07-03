//
//  ContentView.swift
//  QRCodeScannerSample
//
//  Created by 윤병진 on 2022/07/03.
//  SwiftUI에서 적용

import SwiftUI

struct ContentView: View {
    var body: some View {
        QRCodeScanView()
    }
}

struct QRCodeScanView: UIViewRepresentable {
    private let qrScanManager = QRScanManager()
    
    func makeUIView(context: Context) -> some UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        qrScanManager.scanForQRImage(previewIn: view,
                                     scanInterval: 2.0,
                                     offsetY: 24)
        
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) { }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
