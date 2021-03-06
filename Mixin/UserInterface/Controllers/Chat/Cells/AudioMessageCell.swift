import UIKit

class AudioMessageCell: CardMessageCell, AttachmentLoadingMessageCell {
    
    private static let playImage = UIImage(named: "ic_play")
    private static let stopImage = UIImage(named: "ic_file_cancel")

    @IBOutlet weak var operationButton: NetworkOperationButton!
    @IBOutlet weak var playbackStateImageView: UIImageView!
    @IBOutlet weak var waveformView: WaveformView!
    @IBOutlet weak var highlightedWaveformView: WaveformView!
    @IBOutlet weak var lengthLabel: UILabel!
    
    weak var attachmentLoadingDelegate: AttachmentLoadingMessageCellDelegate?
    
    private let waveformMaskView = UIView()
    private let waveformUpdateInterval: TimeInterval = 0.1
    
    private var timer: Timer?
    private var duration: Float64 = 0
    
    var isPlaying = false {
        didSet {
            guard isPlaying != oldValue else {
                return
            }
            let image = isPlaying ? AudioMessageCell.stopImage : AudioMessageCell.playImage
            playbackStateImageView.image = image
            if isPlaying {
                timer = Timer(timeInterval: waveformUpdateInterval, repeats: true, block: { [weak self] (_) in
                    self?.updateWaveformProgress()
                })
                RunLoop.main.add(timer!, forMode: .common)
            } else {
                waveformMaskView.frame = .zero
                timer?.invalidate()
                timer = nil
            }
        }
    }
        
    deinit {
        timer?.invalidate()
        timer = nil
        if let messageId = viewModel?.message.messageId {
            AudioManager.shared.unregister(cell: self, forMessageId: messageId)
        }
    }
    
    override var contentTopMargin: CGFloat {
        return 10
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        waveformMaskView.backgroundColor = .black
        highlightedWaveformView.mask = waveformMaskView
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        isPlaying = false
        waveformMaskView.frame = .zero
        timer?.invalidate()
        timer = nil
        if let messageId = viewModel?.message.messageId {
            AudioManager.shared.unregister(cell: self, forMessageId: messageId)
        }
    }

    override func render(viewModel: MessageViewModel) {
        super.render(viewModel: viewModel)
        if let viewModel = viewModel as? AudioMessageViewModel {
            lengthLabel.text = viewModel.length
            waveformView.waveform = viewModel.waveform
            highlightedWaveformView.waveform = viewModel.waveform
            updateOperationButtonStyle()
            operationButton.isHidden = viewModel.operationButtonIsHidden
            playbackStateImageView.isHidden = viewModel.playbackStateIsHidden
            duration = Float64(viewModel.message.mediaDuration ?? 0)
        }
        AudioManager.shared.register(cell: self, forMessageId: viewModel.message.messageId)
    }
    
    @IBAction func operationAction(_ sender: Any) {
        attachmentLoadingDelegate?.attachmentLoadingCellDidSelectNetworkOperation(self)
    }
    
    func updateOperationButtonStyle() {
        guard let viewModel = viewModel as? AudioMessageViewModel else {
            return
        }
        operationButton.style = viewModel.operationButtonStyle
        operationButton.isHidden = viewModel.operationButtonIsHidden
        playbackStateImageView.isHidden = viewModel.playbackStateIsHidden
    }
    
    private func updateWaveformProgress() {
        let player = AudioManager.shared.player
        let progress = player.currentTime * millisecondsPerSecond / (duration - waveformUpdateInterval * millisecondsPerSecond)
        let oldWidth = waveformMaskView.frame.width
        let newWidth = highlightedWaveformView.frame.width * CGFloat(progress)
        if abs(oldWidth - newWidth) > 0.3 {
            let size = CGSize(width: newWidth, height: highlightedWaveformView.frame.height)
            UIView.animate(withDuration: waveformUpdateInterval) {
                self.waveformMaskView.frame = CGRect(origin: .zero, size: size)
            }
        }
    }

}
