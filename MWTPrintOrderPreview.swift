//
//  MWTPrintOrderPreview.swift
//
//  Created by Diego Giardinetto on 2015/12/23
//	Edited by Diego Giardinetto on 2016/01/12
//
//  License: MIT - https://opensource.org/licenses/MIT
//

import UIKit

// Samples
let kTableHeaderTitles = ["Product name", "Vendor name", "Discount", "Discounted price", "Quantity", "Amount"]

// MARK: - MWTPrintModuleError struct

enum MWTPrintOrderPreviewError: Error {
    case DataNotFound
    case FileSystemError
    case PDFContextOpeningError
    case PDFContectGenericError
}

class MWTPrintOrderPreview: NSObject, MWTPrintModuleDelegate, MWTPrintModuleDataSource {
    var printContext = MWTPrintModule(customPageSize: A4PageSize72dpi)
    var filePath: String = ""
    
    func printOrderWithSessionId(orderRowsData: Array<Dictionary<String,String>>?, withFileName pdfName: String) throws -> String? {
    	// Return if no data: I want to print an order summary, I need order rows
        guard orderRowsData != nil else { throw MWTPrintOrderPreviewError.DataNotFound }
    	
        let documentDir = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.applicationSupportDirectory, .userDomainMask, true)[0] + "/GeneratedPDF/"
        let fm = FileManager.default
        
        if !fm.fileExists(atPath: documentDir) {
            do {
                try fm.createDirectory(atPath: documentDir, withIntermediateDirectories: true, attributes: nil)
            } catch let error1 {
                print("Error creating folder structure")
                print(error1)
                throw MWTPrintOrderPreviewError.FileSystemError
            }
        }
        
	// Enable delegate to draw custom contents
	printContext.delegate = self
	
	// Enable datasource to customize cell height, header height, spacing
	printContext.datasource = self
	
	self.filePath = "" // documentDir + orderObj.orderSessionId + dateAsString + ".pdf"
    if fm.fileExists(atPath: filePath) {
		return filePath
	}
	
	do {
		// Open PDF context to file
        let contextOpened = try printContext.beginContextWithFileName(fileName: filePath)
		if !contextOpened {
			throw MWTPrintOrderPreviewError.PDFContextOpeningError
		}
	} catch _ {
		throw MWTPrintOrderPreviewError.PDFContectGenericError
	}
	
	do {
		// Set table header fields
        printContext.setCustomTableHeaderTitles(headerTitles: kTableHeaderTitles)
		
		// Table header should be present on each table page
        printContext.toggleTableHeaderShouldShowInEveyPage(toggleHeader: true)
		
		// Draw front page): if you use it, you must implement related protocol function
        try printContext.drawFrontPage(compact: false)
		
		// Draw order list
        try printContext.beginTableReport(compact: false)
		
		// Process order rows to create PDF here
        /*
		for orderRowObject in orderRowsData! {
			try printContext.drawReportData(rowData)
		}
        */
		
		// Draw summary page: if you use it, you must implement related protocol function
        try printContext.drawSummaryPage(compact: false)
		
	} catch let pdfError {
        print(pdfError.localizedDescription)
		self.filePath = ""
	}
	
	// Close PDF context
	printContext.closeContext()
	
	// Return NIL Object if error occurred
        if filePath.isEmpty { throw MWTPrintOrderPreviewError.PDFContectGenericError }
        
        // Return generated PDF file
        return filePath
    }
    
    // MARK: - MWTPrintModuleDatasource
    
    // Custom column spacing
    func tableReportColumnSpacing(printModule: MWTPrintModule) -> CGFloat {
        return CGFloat(5.0)
    }
    
    // MARK: - MWTPrintModuleDelegate
    
    // Draw order preview header
    func drawFrontPage(printModule: MWTPrintModule, printablePageDetails: MWTPageSize) {
        // NOTE: draw page elements here
        // Reference: https://developer.apple.com/library/ios/documentation/2DDrawing/Conceptual/DrawingPrintingiOS/GeneratingPDF/GeneratingPDF.html#//apple_ref/doc/uid/TP40010156-CH10-SW5
    }
    
    // Draw summary page
    func drawSummaryPage(printModule: MWTPrintModule, printablePageDetails: MWTPageSize) {
        // NOTE: draw page elements here
        // Reference: https://developer.apple.com/library/ios/documentation/2DDrawing/Conceptual/DrawingPrintingiOS/GeneratingPDF/GeneratingPDF.html#//apple_ref/doc/uid/TP40010156-CH10-SW5
    }
    
    // Draw order table header
    func drawTableHeader(printModule: MWTPrintModule, headerHeight: CGFloat, headerItems: Array<String>, pageSize: MWTPageSize, columnSpacing: CGFloat) {
        // NOTE: draw custom table header here
        // Reference: https://developer.apple.com/library/ios/documentation/2DDrawing/Conceptual/DrawingPrintingiOS/GeneratingPDF/GeneratingPDF.html#//apple_ref/doc/uid/TP40010156-CH10-SW5
    }
    
    // Draw order row
    func drawTableItemRow(printModule: MWTPrintModule, rowHeight: CGFloat, rowData: Dictionary<String,String>, headerItems: Array<String>, pageSize: MWTPageSize, columnSpacing: CGFloat) {
        // NOTE: draw single table row here
        // Reference: https://developer.apple.com/library/ios/documentation/2DDrawing/Conceptual/DrawingPrintingiOS/GeneratingPDF/GeneratingPDF.html#//apple_ref/doc/uid/TP40010156-CH10-SW5
    }
}
