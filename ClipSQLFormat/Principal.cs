using System;
using System.Runtime.InteropServices;
using System.Windows.Forms;
using PoorMansTSqlFormatterLib;
using System.Drawing;

namespace SiQoL
{
    public partial class FPrincipal : Form
    {
        private NotifyIcon trayIcon;
        private ContextMenu trayMenu;

        public FPrincipal()
        {
            InitializeComponent();

            // Create a simple tray menu with only one item.
            trayMenu = new ContextMenu();
            trayMenu.MenuItems.Add("Fechar", OnExit);

            // Create a tray icon. In this example we use a
            // standard system icon for simplicity, but you
            // can of course use your own custom icon too.
            trayIcon = new NotifyIcon();
            trayIcon.Text = "SiQoL - SQL Format Clipboard (by Renatto Machado)";
            trayIcon.Icon = new Icon(Properties.Resources.Clip, 32, 32);

            // Add menu to tray icon and show it.
            trayIcon.ContextMenu = trayMenu;
            trayIcon.Visible = true;
        }

        [DllImport("User32.dll")]
        public static extern IntPtr SetClipboardViewer(IntPtr hwnd);
        private IntPtr proxjanela;

        private void Form1_Load(object sender, EventArgs e)
        {
            proxjanela = SetClipboardViewer(this.Handle);

            Visible = false; // Hide form window.
            ShowInTaskbar = true; // Remove from taskbar.
            Opacity = 0;
        }

        private void OnExit(object sender, EventArgs e)
        {
            Application.Exit();
        }

        [DllImport("user32.dll")]
        public static extern bool ChangeClipboardChain(IntPtr hwndRemove, IntPtr hwndNext);

        private void Form1_FormClosing(object sender, FormClosingEventArgs e)
        {
            ChangeClipboardChain(this.Handle, proxjanela);
        }

        const int WM_DRAWCLIPBOARD = 0x308;
        const int WM_CHANGECBCHAIN = 0x030D;
        [DllImport("user32.dll")]
        public static extern int SendMessage(IntPtr hwnd, int wMsg, IntPtr wParam, IntPtr lParam);

        protected override void WndProc(ref Message m)
        {
            switch (m.Msg)
            {
                case WM_DRAWCLIPBOARD:
                    if (Clipboard.ContainsText())
                    {
                        string lSelect = "select";
                        string lFrom = "from";
                        string lInsert = "insert";
                        string lInto = "into";
                        string lUpdate = "update";
                        string lSet = "set";

                        string clipText = Clipboard.GetText();
                        if ((clipText.ToUpper().Contains(lSelect.ToUpper()) && clipText.ToUpper().Contains(lFrom.ToUpper())) || 
                            (clipText.ToUpper().Contains(lInsert.ToUpper()) && clipText.ToUpper().Contains(lInto.ToUpper())) ||
                            (clipText.ToUpper().Contains(lUpdate.ToUpper()) && clipText.ToUpper().Contains(lSet.ToUpper())) 
                            )
                        {
                            SqlFormattingManager format = new SqlFormattingManager();
                            format.Formatter.ErrorOutputPrefix = "";
                            
                            string sqlFormatado = format.Format(clipText);
                            sqlFormatado = sqlFormatado.Replace(": ", ":");
                            Clipboard.SetText(sqlFormatado);
                            if (!Clipboard.ContainsText())
                            {
                                Clipboard.SetText(clipText);
                            }
                        }
                    }
                    SendMessage(proxjanela, WM_DRAWCLIPBOARD, m.WParam, m.LParam);
                    break;
                case WM_CHANGECBCHAIN:
                    if (m.WParam == proxjanela)
                    {
                        proxjanela = m.LParam;
                    }
                    else
                    {
                        SendMessage(proxjanela, WM_DRAWCLIPBOARD, m.WParam, m.LParam);
                    }
                    break;
                default:
                    base.WndProc(ref m);
                    break;
            }
        }
    }
}
