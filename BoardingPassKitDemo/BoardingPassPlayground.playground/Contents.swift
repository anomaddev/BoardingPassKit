import UIKit
import BoardingPassKit

do {
    let decoder = BoardingPassDecoder()
    let pass = try decoder.decode(code: BoardingPass.scan13)
    
    pass.printout()
} catch {
    print(error.localizedDescription)
}
