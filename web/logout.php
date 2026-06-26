<?php
if (!is_dir(ini_get('session.save_path')) || !is_writable(ini_get('session.save_path'))) {
    session_save_path(sys_get_temp_dir());
}
session_start();
session_unset();
session_destroy();
header('Location: login.php');
exit; 