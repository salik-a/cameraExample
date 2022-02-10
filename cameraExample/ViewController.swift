//
//  ViewController.swift
//  cameraExample
//
//  Created by Alper Salık on 6.02.2022.
//

// import UIKit
//
// class ViewController: UIViewController,UIImagePickerControllerDelegate, UINavigationControllerDelegate {
//
//     @IBOutlet var imageView: UIImageView!
//     @IBOutlet var button: UIButton!
//
//     override func viewDidLoad() {
//         super.viewDidLoad()
//         // Do any additional setup after loading the view.
//
//     }
//
//     @IBAction func didButtonPress(){
//         let picker = UIImagePickerController()
//         picker.sourceType = .camera
//         picker.allowsEditing = true
//         picker.delegate = self
//         present(picker, animated: true)
//     }
//
//     func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
//         picker.dismiss(animated: true, completion: nil)
//     }
//
//     func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
//
//         imageView?.image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage
//         picker.dismiss(animated: true, completion: nil)
//     }
//
// }


//import UIKit
//import VisionKit
//import Vision
//class ViewController: UIViewController,UIImagePickerControllerDelegate, UINavigationControllerDelegate,VNDocumentCameraViewControllerDelegate {
//
//    @IBOutlet var imageView: UIImageView!
//    @IBOutlet var button: UIButton!
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        // Do any additional setup after loading the view.
//
//    }
//
//    @IBAction func didButtonPress(){
//        let scanner = VNDocumentCameraViewController()
//        scanner.delegate = self
//        present(scanner, animated: true)
//
//
//    }
//
//    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
//        picker.dismiss(animated: true, completion: nil)
//    }
//
//    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
//
//        imageView?.image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage
//        picker.dismiss(animated: true, completion: nil)
//    }
//
//
//
//
//    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
//        controller.dismiss(animated: true) { [weak self] in
//            self?.imageView.image = scan.imageOfPage(at: 0)
//
//            guard let strongSelf = self else { return }
//            UIAlertController.present(title: "Success!", message: "Document \(scan.title) scanned with \(scan.pageCount) pages.", on: strongSelf)
//        }
//    }
//
//    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
//        controller.dismiss(animated: true) { [weak self] in
//            self?.imageView.image = nil
//
//            guard let strongSelf = self else { return }
//            UIAlertController.present(title: "Cancelled", message: "User cancelled operation.", on: strongSelf)
//        }
//    }
//
//    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
//        controller.dismiss(animated: true) { [weak self] in
//            self?.imageView.image = nil
//
//            guard let strongSelf = self else { return }
//            UIAlertController.present(title: "Error", message: error.localizedDescription, on: strongSelf)
//        }
//    }
//
//}
//
//extension UIAlertController {
//    static func present(title: String?, message: String?, on viewController: UIViewController) {
//        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
//        let confirm = UIAlertAction(title: "OK", style: .default)
//        alert.addAction(confirm)
//        viewController.present(alert, animated: true)
//    }
//}


import UIKit
import VisionKit
import Vision

class ViewController: UIViewController,UIImagePickerControllerDelegate, UINavigationControllerDelegate,VNDocumentCameraViewControllerDelegate {

    @IBOutlet var imageView: UIImageView!
    @IBOutlet var button: UIButton!
    @IBOutlet weak var textView: UITextView!


    var textRecognitionRequest = VNRecognizeTextRequest(completionHandler: nil)
    private let textRecognitionWorkQueue = DispatchQueue(label: "MyVisionScannerQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        textView.isEditable = false
        setupVision()
    }

    private func setupVision() {
        textRecognitionRequest = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }

            var detectedText = ""
            for observation in observations {
                guard let topCandidate = observation.topCandidates(1).first else { return }
                print("text \(topCandidate.string) has confidence \(topCandidate.confidence)")

                detectedText += topCandidate.string
                detectedText += "\n"


            }

            DispatchQueue.main.async {
                self.textView.text = detectedText
                self.textView.flashScrollIndicators()

            }
        }

        textRecognitionRequest.recognitionLevel = .accurate
    }


    private func recognizeTextInImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else { return }

        textView.text = ""
        textRecognitionWorkQueue.async {
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try requestHandler.perform([self.textRecognitionRequest])
            } catch {
                print(error)
            }
        }
    }
    func compressedImage(_ originalImage: UIImage) -> UIImage {
        guard let imageData = originalImage.jpegData(compressionQuality: 1),
            let reloadedImage = UIImage(data: imageData) else {
                return originalImage
        }
        return reloadedImage
    }


    @IBAction func didButtonPress(){
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = self
        present(scanner, animated: true)


    }

    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        controller.dismiss(animated: true) { [weak self] in
            self?.imageView.image = scan.imageOfPage(at: 0)

            let originalImage = scan.imageOfPage(at: 0)
            let newImage = self?.compressedImage(originalImage)


            self?.recognizeTextInImage(newImage!)

            guard let strongSelf = self else { return }
            UIAlertController.present(title: "Success!", message: "Document \(scan.title) scanned with \(scan.pageCount) pages.", on: strongSelf)
        }
    }

    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true) { [weak self] in
            self?.imageView.image = nil

            guard let strongSelf = self else { return }
            UIAlertController.present(title: "Cancelled", message: "User cancelled operation.", on: strongSelf)
        }
    }

    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        controller.dismiss(animated: true) { [weak self] in
            self?.imageView.image = nil

            guard let strongSelf = self else { return }
            UIAlertController.present(title: "Error", message: error.localizedDescription, on: strongSelf)
        }
    }


}

extension UIAlertController {
    static func present(title: String?, message: String?, on viewController: UIViewController) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let confirm = UIAlertAction(title: "OK", style: .default)
        alert.addAction(confirm)
        viewController.present(alert, animated: true)
    }
}




