//
//  MWTPrintModule.swift
//
//  Created by Diego Giardinetto on 2015/12/23
//	Edited by Diego Giardinetto on 2016/01/12
//
//  License: MIT - https://opensource.org/licenses/MIT
//

import UIKit
import CoreText

// MARK: - MWTPrintModule constants

let kTableItemCellHeight = CGFloat(50.0);
let kTableItemHeaderHeight = CGFloat(20.0);
let kTableItemSpacing = CGFloat(20.0);
let kTableColumnSpacing = CGFloat(20.0);

// MARK: - MWTPrintModuleError struct

enum MWTPrintModuleError: ErrorType {
    case FileNameNULLOrEmpty
    case DelegateIsMissing
    case HeaderTitlesAreMissing
    case RowDataAreMissing
    case GenericError
}

// MARK: - MWTPageSize struct

let MWTPrintModuleBasePrintableMargin: CGFloat = CGFloat(36.0)

struct MWTPageSize {
    let width: CGFloat
    let height: CGFloat
    
    // Print margins
    var topMargin: CGFloat = MWTPrintModuleBasePrintableMargin
    var rightMargin: CGFloat = MWTPrintModuleBasePrintableMargin
    var bottomMargin: CGFloat = MWTPrintModuleBasePrintableMargin
    var leftMargin: CGFloat = MWTPrintModuleBasePrintableMargin
    
    // Init
    
    init() {
        width = CGFloat(595.0)
        height = CGFloat(842.0)
    }
    
    init(customWidth: CGFloat, customHeight: CGFloat) {
        width = customWidth
        height = customHeight
    }
}

struct MWTCurrentPrintJob {
    var currentPage: Int = 0
    var currentPosition: CGFloat = CGFloat(0.0)
    var currentRowPosition: CGFloat = CGFloat(0.0)
    
    var rowOrigin: CGFloat = CGFloat(0.0)
    var pageOrigin: CGFloat = CGFloat(0.0)
    
    // Init
    
    init() {
        currentPage = 0
        currentPosition = CGFloat(0.0)
        currentRowPosition = CGFloat(0.0)
        
        pageOrigin = CGFloat(0.0)
        rowOrigin = CGFloat(0.0)
    }
    
    init(printablePageDetails: MWTPageSize) {
        currentPage = 0
        currentPosition = printablePageDetails.topMargin
        currentRowPosition = printablePageDetails.leftMargin
        
        pageOrigin = printablePageDetails.topMargin
        rowOrigin = printablePageDetails.leftMargin
    }
}

// MARK: - MWTPrintModuleDataSource

protocol MWTPrintModuleDataSourceOptional {
    func tableReportHeaderHeight(printModule: MWTPrintModule) -> CGFloat
    func tableReportCellHeight(printModule: MWTPrintModule) -> CGFloat
    func tableReportItemSpacing(printModule: MWTPrintModule) -> CGFloat
    func tableReportColumnSpacing(printModule: MWTPrintModule) -> CGFloat
}

extension MWTPrintModuleDataSourceOptional {
    func tableReportHeaderHeight(printModule: MWTPrintModule) -> CGFloat { return kTableItemHeaderHeight }
    func tableReportCellHeight(printModule: MWTPrintModule) -> CGFloat { return kTableItemCellHeight }
    func tableReportItemSpacing(printModule: MWTPrintModule) -> CGFloat { return kTableItemSpacing }
    func tableReportColumnSpacing(printModule: MWTPrintModule) -> CGFloat { return kTableColumnSpacing }
}

protocol MWTPrintModuleDataSource: MWTPrintModuleDataSourceOptional {
}

// MARK: - MWTPrintModuleDelegate

protocol MWTPrintModuleDelegateOptional {
    func drawFrontPage(printModule: MWTPrintModule, printablePageDetails: MWTPageSize)
    func drawSummaryPage(printModule: MWTPrintModule, printablePageDetails: MWTPageSize)
}

extension MWTPrintModuleDelegateOptional {
    func drawFrontPage(printModule: MWTPrintModule, printablePageDetails: MWTPageSize) { }
    func drawSummaryPage(printModule: MWTPrintModule, printablePageDetails: MWTPageSize) { }
}

protocol MWTPrintModuleDelegate: MWTPrintModuleDelegateOptional {
    func drawTableHeader(printModule: MWTPrintModule, headerHeight: CGFloat, headerItems: Array<String>, pageSize: MWTPageSize, columnSpacing: CGFloat)
    func drawTableItemRow(printModule: MWTPrintModule, rowHeight: CGFloat, rowData: Dictionary<String,String>, headerItems: Array<String>, pageSize: MWTPageSize, columnSpacing: CGFloat)
}

// MARK: - MWTPrintModule class

let A4PageSize72dpi = MWTPageSize(customWidth: 595.0, customHeight: 842.0)

class MWTPrintModule: NSObject {
    
    private var printablePageDetails = A4PageSize72dpi
    var printJobDetails = MWTCurrentPrintJob(printablePageDetails: A4PageSize72dpi)
    
    // Table drawing components definition
    
    private let tableItemCellHeight = kTableItemCellHeight
    private let tableItemHeaderHeight = kTableItemHeaderHeight
    private let tableItemSpacing = kTableItemHeaderHeight
    private let tableColumnSpacing = kTableItemHeaderHeight
    
    private var tableHeaderShouldShowInEveyPage: Bool = false
    private var tableHeaderTitles: Array<String>?
    
    // PDF Context Management
    
    private var contextIsOpen = false
    
    // MARK: --- Public
    
    var delegate: MWTPrintModuleDelegate?
    var datasource: MWTPrintModuleDataSource?
    
    // Init
    init(customPageSize: MWTPageSize?) {
        if let cps = customPageSize {
            printablePageDetails = cps
            printJobDetails = MWTCurrentPrintJob(printablePageDetails: cps)
        }
    }
    
    // MARK: - Drawing functions
    
    // MARK: --- Context management
    
    // Open PDF Context
    func beginContextWithFileName(fileName: String?) throws -> Bool {
        if let pdfFileName = fileName {
            self.contextIsOpen = UIGraphicsBeginPDFContextToFile(pdfFileName, CGRectZero, nil);
            return contextIsOpen
            
        } else {
            throw MWTPrintModuleError.FileNameNULLOrEmpty
        }
    }
    
    // Close PDF Context
    func closeContext() {
        if contextIsOpen { UIGraphicsEndPDFContext(); }
        contextIsOpen = false
    }
    
    // MARK: --- Accessory pages
    
    // Draw front page
    func drawFrontPage() throws {
        guard delegate != nil else { throw MWTPrintModuleError.DelegateIsMissing }
        
        printJobDetails.currentPosition = printJobDetails.pageOrigin
        printJobDetails.currentRowPosition = printJobDetails.rowOrigin
        
        UIGraphicsBeginPDFPageWithInfo(CGRectMake(0, 0, printablePageDetails.width, printablePageDetails.height), nil)
        self.delegate?.drawFrontPage(self, printablePageDetails: printablePageDetails)
        
        printJobDetails.currentPage++
        printJobDetails.currentPosition = printJobDetails.pageOrigin
        printJobDetails.currentRowPosition = printJobDetails.rowOrigin
    }
    
    // Draw summary page
    func drawSummaryPage() throws {
        guard delegate != nil else { throw MWTPrintModuleError.DelegateIsMissing }
        
        printJobDetails.currentPosition = printJobDetails.pageOrigin
        printJobDetails.currentRowPosition = printJobDetails.rowOrigin
        
        UIGraphicsBeginPDFPageWithInfo(CGRectMake(0, 0, printablePageDetails.width, printablePageDetails.height), nil)
        self.delegate?.drawSummaryPage(self, printablePageDetails: printablePageDetails)
        
        printJobDetails.currentPage++
        printJobDetails.currentPosition = printJobDetails.pageOrigin
        printJobDetails.currentRowPosition = printJobDetails.rowOrigin
    }
    
    // MARK: --- Table report formatting
    
    func getTableCellHeight() -> CGFloat {
        let currentCellHeight: CGFloat
        
        if let datasourceObj = self.datasource {
            currentCellHeight = datasourceObj.tableReportCellHeight(self)
        } else {
            currentCellHeight = self.tableItemCellHeight
        }
        
        return currentCellHeight
    }
    
    func getTableHeaderHeight() -> CGFloat {
        let currentHeaderHeight: CGFloat
        
        if let datasourceObj = self.datasource {
            currentHeaderHeight = datasourceObj.tableReportHeaderHeight(self)
        } else {
            currentHeaderHeight = self.tableItemHeaderHeight
        }
        
        return currentHeaderHeight
    }
    
    // Define header's titles for table
    func setCustomTableHeaderTitles(headerTitles: Array<String>?) {
        self.tableHeaderTitles = headerTitles
    }
    
    // Set if header must repeat every page
    func toggleTableHeaderShouldShowInEveyPage(toggleHeader: Bool) {
        self.tableHeaderShouldShowInEveyPage = toggleHeader
    }
    
    // Draw table header
    private func drawReportTableHeader() throws {
        guard delegate != nil else { throw MWTPrintModuleError.DelegateIsMissing }
        
        let currentSpacing: CGFloat
        let currentColumnSpacing: CGFloat
        let currentHeaderHeight: CGFloat
        
        if let datasourceObj = self.datasource {
            currentColumnSpacing = datasourceObj.tableReportColumnSpacing(self)
            currentSpacing = datasourceObj.tableReportItemSpacing(self)
            currentHeaderHeight = datasourceObj.tableReportHeaderHeight(self)
        } else {
            currentColumnSpacing = self.tableColumnSpacing
            currentSpacing = self.tableItemSpacing
            currentHeaderHeight = self.tableItemHeaderHeight
        }
        
        if let headerItems = self.tableHeaderTitles {
            self.delegate?.drawTableHeader(self, headerHeight: currentHeaderHeight, headerItems: headerItems, pageSize: printablePageDetails, columnSpacing: currentColumnSpacing)
        }
        
        printJobDetails.currentPosition += currentHeaderHeight + currentSpacing
        printJobDetails.currentRowPosition = printJobDetails.rowOrigin
    }
    
    // Set context on new empty page to start drawing table report and draw table header
    func beginTableReport() throws {
        guard delegate != nil else { throw MWTPrintModuleError.DelegateIsMissing }
        
        UIGraphicsBeginPDFPageWithInfo(CGRectMake(0, 0, printablePageDetails.width, printablePageDetails.height), nil)
        
        do {
            try self.drawReportTableHeader()
            
        } catch MWTPrintModuleError.DelegateIsMissing {
            throw MWTPrintModuleError.DelegateIsMissing
            
        } catch let error1 {
            throw MWTPrintModuleError.GenericError
        }
    }
    
    // Draw table report data
    func drawReportData(rowData: Dictionary<String,String>?) throws {
        guard delegate != nil else { throw MWTPrintModuleError.DelegateIsMissing }
        
        if let singleRow = rowData {
            let currentCellHeight: CGFloat
            let currentSpacing: CGFloat
            let currentColumnSpacing: CGFloat
            
            if let datasourceObj = self.datasource {
                currentCellHeight = datasourceObj.tableReportCellHeight(self)
                currentSpacing = datasourceObj.tableReportItemSpacing(self)
                currentColumnSpacing = datasourceObj.tableReportColumnSpacing(self)
            } else {
                currentCellHeight = self.tableItemCellHeight
                currentSpacing = self.tableItemSpacing
                currentColumnSpacing = self.tableColumnSpacing
            }
            
            // Add new page if bottom margin reached
            if (printJobDetails.currentPosition + currentCellHeight + currentSpacing) > (printablePageDetails.height - printablePageDetails.bottomMargin) {
                UIGraphicsBeginPDFPageWithInfo(CGRectMake(0, 0, printablePageDetails.width, printablePageDetails.height), nil)
                printJobDetails.currentPage++
                printJobDetails.currentPosition = printJobDetails.pageOrigin
                printJobDetails.currentRowPosition = printJobDetails.rowOrigin
                
                if tableHeaderShouldShowInEveyPage {
                    do {
                        try self.drawReportTableHeader()
                        
                    } catch MWTPrintModuleError.DelegateIsMissing {
                        throw MWTPrintModuleError.DelegateIsMissing
                        
                    } catch let error1 {
                        throw MWTPrintModuleError.GenericError
                    }
                }
            }
            
            // Draw single table row here
            if let headerItems = self.tableHeaderTitles {
                self.delegate?.drawTableItemRow(self, rowHeight: currentCellHeight, rowData: singleRow, headerItems: headerItems, pageSize: printablePageDetails, columnSpacing: currentColumnSpacing)
            }
            
            // Reset row origin position and update vertical position (CR,LF)
            printJobDetails.currentPosition += currentCellHeight + currentSpacing
            printJobDetails.currentRowPosition = printJobDetails.rowOrigin
         }
    }
}
