import CU8g2

// MARK: - Router

/// Manages page navigation and modal presentations.
///
/// The `Router` maintains a stack of pages and handles transitions between them.
/// It also supports displaying modal overlays such as alerts.
public class Router {
    // MARK: - Private Properties
    
    /// The navigation stack of pages.
    private var stack: [Page] = []
    
    /// A page that is currently playing its exit animation.
    private var exitingPage: Page?
    
    // MARK: - Public Properties
    
    /// The currently displayed modal view (e.g., alert or toast).
    public var modal: View?
    
    /// The topmost page in the navigation stack.
    public var topPage: Page? {
        return stack.last
    }
    
    // MARK: - Initialization
    
    /// Initializes a new router.
    public init() {}
    
    // MARK: - Navigation Methods
    
    /// Pushes a new page onto the navigation stack.
    /// - Parameter page: The page to push.
    public func push(_ page: Page) {
        stack.append(page)
        page.onEnter()
        page.animateIn()
    }
    
    /// Pops the top page from the navigation stack.
    ///
    /// The popped page will play its exit animation before being removed.
    /// The previous page in the stack will become active.
    public func pop() {
        guard stack.count > 1 else { return }
        
        exitingPage = stack.popLast()
        exitingPage?.animateOut()
        exitingPage?.onExit()
        
        if let current = stack.last {
            current.onEnter()
            current.animateIn()
        }
    }
    
    /// Replaces the current top page with a new page.
    /// - Parameter page: The new page to display.
    public func replace(with page: Page) {
        if !stack.isEmpty {
            _ = stack.popLast()
        }
        push(page)
    }
    
    /// Sets the root page, clearing the navigation stack.
    /// - Parameter page: The root page to set.
    public func setRoot(_ page: Page) {
        stack.removeAll()
        stack.append(page)
        page.onEnter()
        page.animateIn()
    }
    
    // MARK: - Modal Methods
    
    /// Presents a modal view (e.g., alert or toast).
    /// - Parameter view: The modal view to present.
    public func present(_ view: View) {
        modal = view
    }
    
    /// Dismisses the currently displayed modal.
    ///
    /// If the modal is a `ModalView`, it will play its dismiss animation
    /// before being removed.
    public func dismissModal() {
        if let modalView = modal as? ModalView {
            modalView.dismiss {
                self.modal = nil
            }
        } else {
            modal = nil
        }
    }
    
    // MARK: - Rendering
    
    /// Renders the current navigation state.
    ///
    /// This draws the previous page (if transitioning), the current page,
    /// any exiting page animation, and modals.
    ///
    /// - Parameter u8g2: Pointer to the u8g2 graphics context.
    public func draw(u8g2: UnsafeMutablePointer<u8g2_t>?) {
        guard let u8g2 = u8g2 else { return }
        
        let count = stack.count
        
        // Draw previous page (for smooth transitions)
        if count > 1 {
            let previous = stack[count - 2]
            previous.draw(u8g2: u8g2, origin: .zero)
        }
        
        // Draw current page
        if let current = stack.last {
            current.draw(u8g2: u8g2, origin: .zero)
        }
        
        // Draw exiting page (on top during exit animation)
        if let exiting = exitingPage {
            exiting.draw(u8g2: u8g2, origin: .zero)
            
            if exiting.isExitAnimationFinished() {
                exitingPage = nil
            }
        }
        
        // Draw modal overlay
        if let modal = modal {
            modal.draw(u8g2: u8g2, origin: .zero)
        }
    }
    
    // MARK: - Input Handling
    
    /// Dispatches input to modal first, then to the top page.
    /// - Parameter key: The key code of the pressed key.
    public func handleInput(key: Int32) {
        // If there's a modal, handle input there first
        if let modal = modal {
            // 'q' (113) -> Close modal
            if key == 113 {
                dismissModal()
                return
            }
            
            // Let modal handle other input
            if let progressView = modal as? ProgressView {
                progressView.handleInput(key: key)
                return
            }
            
            // For other modals, return early (they handle their own input)
            return
        }
        
        // Otherwise, dispatch to the top page
        if let page = stack.last {
            page.handleInput(key: key)
        }
    }
}
