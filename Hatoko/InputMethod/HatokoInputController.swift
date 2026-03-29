import Cocoa
import InputMethodKit

@objc(HatokoInputController)
final class HatokoInputController: IMKInputController {

    private var inputMode: InputMode = .japanese

    override init!(server: IMKServer!, delegate: Any!, client inputClient: Any!) {
        super.init(server: server, delegate: delegate, client: inputClient)
    }

    override func activateServer(_ sender: Any!) {
        super.activateServer(sender)
    }

    override func deactivateServer(_ sender: Any!) {
        super.deactivateServer(sender)
    }

    override func setValue(_ value: Any!, forTag tag: Int, client sender: Any!) {
        guard let value = value as? String else { return }
        if value.hasSuffix("Roman") {
            inputMode = .roman
        } else {
            inputMode = .japanese
        }
        super.setValue(value, forTag: tag, client: sender)
    }

    override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
        guard let event else { return false }
        _ = event

        // TODO: 1-2 でかな漢字変換パイプラインを実装
        // TODO: 1-4 でアクティブモードトリガーを実装

        return false
    }

    override func commitComposition(_ sender: Any!) {
        super.commitComposition(sender)
    }
}
