--------------------------------------------------------------------------------
-- |
-- Module      :  Graphics.UI.GLUT.Window
-- Copyright   :  (c) Sven Panne 2002
-- License     :  BSD-style (see the file libraries/GLUT/LICENSE)
-- 
-- Maintainer  :  sven_panne@yahoo.com
-- Stability   :  experimental
-- Portability :  portable
--
-- GLUT supports two types of windows: top-level windows and subwindows. Both
-- types support OpenGL rendering and GLUT callbacks. There is a single
-- identifier space for both types of windows.
--
--------------------------------------------------------------------------------

module Graphics.UI.GLUT.Window (
   -- * Window identifiers
   Window,

   -- * Creating and destroying (sub-)windows

   -- $CreatingAndDestroyingSubWindows
   createWindow, createSubWindow, destroyWindow,

   -- * Manipulating the /current window/
   setWindow, getWindow,

   -- * Re-displaying and double buffer management
   postRedisplay, postWindowRedisplay, swapBuffers,

   -- * Changing the window geometry

   -- $ChangingTheWindowGeometry
   positionWindow, reshapeWindow, fullScreen,

   -- * Manipulating the stacking order

   -- $ManipulatingTheStackingOrder
   pushWindow, popWindow,

   -- * Managing the display status

   -- $ManagingTheDisplayStatus
   showWindow, hideWindow, iconifyWindow,

   -- * Changing the window\/icon title

   -- $ChangingTheWindowIconTitle
   setWindowTitle, setIconTitle,

   -- * Cursor management
   Cursor(..), setCursor, warpPointer
) where

import Foreign.C.String ( CString, withCString )
import Foreign.C.Types ( CInt )
import Graphics.UI.GLUT.Initialization ( WindowPosition(..), WindowSize(..) )
import Graphics.UI.GLUT.Constants

--------------------------------------------------------------------------------

-- | An opaque identifier for a top-level window or a subwindow.

newtype Window = Window CInt deriving ( Eq, Ord )

--------------------------------------------------------------------------------

-- $CreatingAndDestroyingSubWindows
-- Each created window has a unique associated OpenGL context. State changes to
-- a window\'s associated OpenGL context can be done immediately after the
-- window is created.
--
-- The /display state/ of a window is initially for the window to be shown. But
-- the window\'s /display state/ is not actually acted upon until
-- 'Graphics.UI.GLUT.Begin.mainLoop' is entered. This means until
-- 'Graphics.UI.GLUT.Begin.mainLoop' is called, rendering to a created window is
-- ineffective because the window can not yet be displayed.
--
-- The value returned by 'createWindow' and 'createSubWindow' is a unique
-- identifier for the window, which can be used when calling 'setWindow'.

-- | Create a top-level window. The given name will be provided to the window
-- system as the window\'s name. The intent is that the window system will label
-- the window with the name.Implicitly, the /current window/ is set to the newly
-- created window.
--
-- /X Implementation Notes:/ The proper X Inter-Client Communication Conventions
-- Manual (ICCCM) top-level properties are established. The @WM_COMMAND@
-- property that lists the command line used to invoke the GLUT program is only
-- established for the first window created.

createWindow
   :: String    -- @ The window name
   -> IO Window -- @ The identifier for the newly created window
createWindow name = withCString name glutCreateWindow

foreign import ccall unsafe "glutCreateWindow" glutCreateWindow ::
      CString -> IO Window

-- | Create a subwindow of the identified window with the given relative
-- position and size. Implicitly, the /current window/ is set to the
-- newly created subwindow. Subwindows can be nested arbitrarily deep.

createSubWindow
   :: Window         -- @ Identifier of the subwindow\'s parent window.
   -> WindowPosition -- @ Window position in pixels relative to parent window\'s origin.
   -> WindowSize     -- @ Window size in pixels
   -> IO Window      -- @ The identifier for the newly created subwindow
createSubWindow win (WindowPosition x y) (WindowSize w h) =
   glutCreateSubWindow win x y w h

foreign import ccall unsafe "glutCreateSubWindow" glutCreateSubWindow ::
      Window -> CInt -> CInt -> CInt -> CInt -> IO Window

-- | Destroy the specified window and the window\'s associated OpenGL context,
-- logical colormap (if the window is color index), and overlay and related
-- state (if an overlay has been established). Any subwindows of the destroyed
-- window are also destroyed by 'destroyWindow'. If the specified window was the
-- /current window/, the /current window/ becomes invalid ('getWindow' will
-- return 'Nothing').

foreign import ccall unsafe "glutDestroyWindow" destroyWindow :: Window -> IO ()

--------------------------------------------------------------------------------

-- | Set the /current window/. It does /not/ change the /layer in use/ for the
-- window; this is done using 'useLayer'.

foreign import ccall unsafe "glutSetWindow" setWindow :: Window -> IO ()

-- | Return 'Just' the identifier of the /current window/. If no windows exist
-- or thepreviously /current window/ was destroyed, 'Nothing' is returned.

getWindow :: IO (Maybe Window)
getWindow = do
   w <- glutGetWindow
   return $ if w == Window 0 then Nothing else Just w

foreign import ccall unsafe "glutGetWindow" glutGetWindow :: IO Window

--------------------------------------------------------------------------------

-- | Mark the normal plane of /current window/ as needing to be redisplayed.
-- The next iteration through 'Graphics.UI.GLUT.mainLoop', the window\'s display
-- callback will be called to redisplay the window\'s normal plane. Multiple
-- calls to 'postRedisplay' before the next display callback opportunity
-- generates only a single redisplay callback. 'postRedisplay' may be called
-- within a window\'s display or overlay display callback to re-mark that window
-- for redisplay.
--
-- Logically, normal plane damage notification for a window is treated as a
-- 'postRedisplay' on the damaged window. Unlike damage reported by the window
-- system, 'postRedisplay' will /not/ set to true the normal plane\'s damaged
-- status (returned by @'LayerGet' 'NormalDamaged'@).
--
-- Also, see 'Graphics.UI.GLUT.Overlay.postOverlayRedisplay'.

foreign import ccall unsafe "glutPostRedisplay" postRedisplay :: IO ()

-- | Mark the normal plane of the given window as needing to be redisplayed,
-- otherwise the same as 'postRedisplay'.
--
-- The advantage of this routine is that it saves the cost of a 'setWindow' call
-- (entailing an expensive OpenGL context switch), which is particularly useful
-- when multiple windows need redisplays posted at the same time. 
--
-- Also, see 'Graphics.UI.GLUT.Overlay.postWindowOverlayRedisplay'.

foreign import ccall unsafe "glutPostWindowRedisplay" postWindowRedisplay ::
   Window -> IO ()

-- | Perform a buffer swap on the /layer in use/ for the /current window/.
-- Specifically, 'swapBuffers' promotes the contents of the back buffer of the
-- /layer in use/ of the /current window/ to become the contents of the front
-- buffer. The contents of the back buffer then become undefined. The update
-- typically takes place during the vertical retrace of the monitor, rather than
-- immediately after 'swapBuffers' is called.
--
-- An implicit 'Graphics.Rendering.OpenGL.flush' is done by 'swapBuffers' before
-- it returns. Subsequent OpenGL commands can be issued immediately after
-- calling 'swapBuffers', but are not executed until the buffer exchange is
-- completed.
--
-- If the /layer in use/ is not double buffered, 'swapBuffers' has no effect.

foreign import ccall unsafe "glutSwapBuffers" swapBuffers :: IO ()

--------------------------------------------------------------------------------

-- $ChangingTheWindowGeometry
-- Note that the requests by 'positionWindow', 'reshapeWindow', and 'fullScreen'
-- are not processed immediately. A request is executed after returning to the
-- main event loop. This allows multiple requests to the same window to be
-- coalesced.
--
-- 'reshapeWindow' and 'positionWindow' requests on a window will disable the
-- full screen status of the window.

-- | Request a change in the position of the /current window/. For top-level
-- windows, parameters of 'WindowPosition' are pixel offsets from the screen
-- origin. For subwindows, the parameters are pixel offsets from the window\'s
-- parent window origin.
--
-- In the case of top-level windows, a 'positionWindow' call is considered only
-- a request for positioning the window. The window system is free to apply its
-- own policies to top-level window placement. The intent is that top-level
-- windows should be repositioned according 'positionWindow'\'s parameter.

positionWindow :: WindowPosition -> IO ()
positionWindow (WindowPosition x y) = glutPositionWindow x y

foreign import ccall unsafe "glutPositionWindow" glutPositionWindow ::
   CInt -> CInt -> IO ()

-- | Request a change in the size of the /current window/. The parameters of
-- 'WindowSize' are size extents in pixels. The width and height must be
-- positive values.
--
-- In the case of top-level windows, a 'reshapeWindow' call is considered only a
-- request for sizing the window. The window system is free to apply its own
-- policies to top-level window sizing. The intent is that top-level windows
-- should be reshaped according 'reshapeWindow'\'s parameters. Whether a
-- reshape actually takes effect and, if so, the reshaped dimensions are
-- reported to the program by a reshape callback.

reshapeWindow :: WindowSize -> IO ()
reshapeWindow (WindowSize w h) = glutReshapeWindow w h

foreign import ccall unsafe "glutReshapeWindow" glutReshapeWindow ::
   CInt -> CInt -> IO ()

-- | Request that the /current window/ be made full screen. The exact semantics
-- of what full screen means may vary by window system. The intent is to make
-- the window as large as possible and disable any window decorations or borders
-- added the window system. The window width and height are not guaranteed to be
-- the same as the screen width and height, but that is the intent of making a
-- window full screen.
--
-- 'fullScreen' is defined to work only on top-level windows.
--
-- /X Implementation Notes:/ In the X implementation of GLUT, full screen is
-- implemented by sizing and positioning the window to cover the entire screen
-- and posting the @_MOTIF_WM_HINTS@ property on the window requesting
-- absolutely no decorations. Non-Motif window managers may not respond to
-- @_MOTIF_WM_HINTS@.

foreign import ccall unsafe "glutFullScreen" fullScreen :: IO ()

--------------------------------------------------------------------------------

-- $ManipulatingTheStackingOrder
-- 'pushWindow' and 'popWindow' work on both top-level windows and subwindows.
-- The effect of pushing and popping windows does not take place immediately.
-- Instead the push or pop is saved for execution upon return to the GLUT event
-- loop. Subsequent pop or push requests on a window replace the previously
-- saved request for that window. The effect of pushing and popping top-level
-- windows is subject to the window system\'s policy for restacking windows.

-- | Change the stacking order of the /current window/ relative to its siblings
-- (lowering it).

foreign import ccall unsafe "glutPushWindow" pushWindow :: IO ()

-- | Change the stacking order of the /current window/ relative to its siblings,
-- bringing the /current window/ closer to the top.

foreign import ccall unsafe "glutPopWindow" popWindow :: IO ()

--------------------------------------------------------------------------------

-- $ManagingTheDisplayStatus
-- Note that the effect of showing, hiding, and iconifying windows does not take
-- place immediately. Instead the requests are saved for execution upon return
-- to the GLUT event loop. Subsequent show, hide, or iconification requests on a
-- window replace the previously saved request for that window. The effect of
-- hiding, showing, or iconifying top-level windows is subject to the window
-- system\'s policy for displaying windows.


-- | Show the /current window/ (though it may still not be visible if obscured by
-- other shown windows).

foreign import ccall unsafe "glutShowWindow" showWindow :: IO ()

-- | Hide the /current window/.

foreign import ccall unsafe "glutHideWindow" hideWindow :: IO ()

-- | Iconify a top-level window. Note that GLUT prohibits iconification of a
-- subwindow.

foreign import ccall unsafe "glutIconifyWindow" iconifyWindow :: IO ()

--------------------------------------------------------------------------------

-- $ChangingTheWindowIconTitle
-- 'setWindowTitle' and 'setIconTitle' should be called only when the /current
-- window/ is a top-level window. Upon creation of a top-level window, the
-- window and icon names are determined by the name given to 'createWindow'.
-- Once created, 'setWindowTitle' and 'setIconTitle' can change the window and
-- icon names respectively of top-level windows. Each call requests the window
-- system change the title appropriately. Requests are not buffered or
-- coalesced. The policy by which the window and icon name are displayed is
-- window system dependent.

-- | Set the window title of the /current top-level window/.

setWindowTitle :: String -> IO ()
setWindowTitle name = withCString name glutSetWindowTitle

foreign import ccall unsafe "glutSetWindowTitle" glutSetWindowTitle ::
      CString -> IO ()

-- | Set the icon title of the /current top-level window/.

setIconTitle :: String -> IO ()
setIconTitle name = withCString name glutSetIconTitle

foreign import ccall unsafe "glutSetIconTitle" glutSetIconTitle ::
      CString -> IO ()

--------------------------------------------------------------------------------

-- |
data Cursor
   = CursorRightArrow        -- ^ Arrow pointing up and to the right.
   | CursorLeftArrow         -- ^ Arrow pointing up and to the left.
   | CursorInfo              -- ^ Pointing hand.
   | CursorDestroy           -- ^ Skull & cross bones.
   | CursorHelp              -- ^ Question mark.
   | CursorCycle             -- ^ Arrows rotating in a circle.
   | CursorSpray             -- ^ Spray can.
   | CursorWait              -- ^ Wrist watch.
   | CursorText              -- ^ Insertion point cursor for text.
   | CursorCrosshair         -- ^ Simple cross-hair.
   | CursorUpDown            -- ^ Bi-directional pointing up & down.
   | CursorLeftRight         -- ^ Bi-directional pointing left & right.
   | CursorTopSide           -- ^ Arrow pointing to top side.
   | CursorBottomSide        -- ^ Arrow pointing to bottom side.
   | CursorLeftSide          -- ^ Arrow pointing to left side.
   | CursorRightSide         -- ^ Arrow pointing to right side.
   | CursorTopLeftCorner     -- ^ Arrow pointing to top-left corner.
   | CursorTopRightCorner    -- ^ Arrow pointing to top-right corner.
   | CursorBottomRightCorner -- ^ Arrow pointing to bottom-left corner.
   | CursorBottomLeftCorner  -- ^ Arrow pointing to bottom-right corner.
   | CursorInherit           -- ^ Use parent\'s cursor.
   | CursorNone              -- ^ Invisible cursor.
   | CursorFullCrosshair     -- ^ Full-screen cross-hair cursor (if possible, otherwise 'CursorCrosshair').
   deriving ( Eq, Ord )

marshalCursor :: Cursor -> CInt
marshalCursor c = case c of
   CursorRightArrow        -> glut_CURSOR_RIGHT_ARROW
   CursorLeftArrow         -> glut_CURSOR_LEFT_ARROW
   CursorInfo              -> glut_CURSOR_INFO
   CursorDestroy           -> glut_CURSOR_DESTROY
   CursorHelp              -> glut_CURSOR_HELP
   CursorCycle             -> glut_CURSOR_CYCLE
   CursorSpray             -> glut_CURSOR_SPRAY
   CursorWait              -> glut_CURSOR_WAIT
   CursorText              -> glut_CURSOR_TEXT
   CursorCrosshair         -> glut_CURSOR_CROSSHAIR
   CursorUpDown            -> glut_CURSOR_UP_DOWN
   CursorLeftRight         -> glut_CURSOR_LEFT_RIGHT
   CursorTopSide           -> glut_CURSOR_TOP_SIDE
   CursorBottomSide        -> glut_CURSOR_BOTTOM_SIDE
   CursorLeftSide          -> glut_CURSOR_LEFT_SIDE
   CursorRightSide         -> glut_CURSOR_RIGHT_SIDE
   CursorTopLeftCorner     -> glut_CURSOR_TOP_LEFT_CORNER
   CursorTopRightCorner    -> glut_CURSOR_TOP_RIGHT_CORNER
   CursorBottomRightCorner -> glut_CURSOR_BOTTOM_RIGHT_CORNER
   CursorBottomLeftCorner  -> glut_CURSOR_BOTTOM_LEFT_CORNER
   CursorInherit           -> glut_CURSOR_INHERIT
   CursorNone              -> glut_CURSOR_NONE
   CursorFullCrosshair     -> glut_CURSOR_FULL_CROSSHAIR

-- | Change the cursor image of the /current window/. Each call requests the
-- window system change the cursor appropriately. The cursor image when a window
-- is created is 'CursorInherit'. The exact cursor images used are
-- implementation dependent. The intent is for the image to convey the meaning
-- of the cursor name. For a top-level window, 'CursorInherit' uses the default
-- window system cursor.
--
-- /X Implementation Notes:/ GLUT for X uses SGI\'s @_SGI_CROSSHAIR_CURSOR@
-- convention to access a full-screen cross-hair cursor if possible.

setCursor :: Cursor -> IO ()
setCursor = glutSetCursor . marshalCursor

foreign import ccall unsafe "glutSetCursor" glutSetCursor :: CInt -> IO ()

-- | Warp the window system\'s pointer to a new location relative to the origin
-- of the /current window/ by the specified pixel offset, which may be negative.
-- The warp is done immediately.
--
-- If the pointer would be warped outside the screen\'s frame buffer region, the
-- location will be clamped to the nearest screen edge. The window system is
-- allowed to further constrain the pointer\'s location in window system
-- dependent ways.
--
-- Good advice from Xlib\'s @XWarpPointer@ man page: \"There is seldom any
-- reason for calling this function. The pointer should normally be left to the
-- user.\"

warpPointer :: WindowPosition -> IO ()
warpPointer (WindowPosition x y) = glutWarpPointer x y

foreign import ccall unsafe "glutWarpPointer" glutWarpPointer ::
   CInt -> CInt -> IO ()
