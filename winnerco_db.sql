-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Hôte : localhost:3306
-- Généré le : lun. 19 jan. 2026 à 14:34
-- Version du serveur : 10.11.15-MariaDB-cll-lve
-- Version de PHP : 8.4.15

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de données : `winnerco_db`
--

DELIMITER $$
--
-- Procédures
--
$$

$$

$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `clients`
--

CREATE TABLE `clients` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `email` varchar(100) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `address` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `clients`
--

INSERT INTO `clients` (`id`, `name`, `email`, `phone`, `address`, `created_at`) VALUES
(59, 'mwisa', NULL, NULL, NULL, '2026-01-03 09:11:00'),
(60, 'kasongo', NULL, NULL, NULL, '2026-01-12 10:59:16'),
(61, 'Moïse pakimo', NULL, NULL, NULL, '2026-01-12 11:51:53'),
(62, 'deux cleant  différents', NULL, NULL, NULL, '2026-01-12 12:11:51'),
(63, 'pitchen', NULL, NULL, NULL, '2026-01-12 12:16:30'),
(64, 'pitchen et un autres client', NULL, NULL, NULL, '2026-01-12 12:18:35'),
(65, 'un client', NULL, NULL, NULL, '2026-01-12 12:31:23'),
(66, 'bienfait komby', NULL, NULL, NULL, '2026-01-12 12:39:06'),
(67, 'deux client', NULL, NULL, NULL, '2026-01-12 12:50:42'),
(68, 'cherment', NULL, NULL, NULL, '2026-01-12 12:52:52'),
(69, 'un clients', NULL, NULL, NULL, '2026-01-12 13:14:14'),
(70, 'chukuru', NULL, NULL, NULL, '2026-01-12 13:47:15'),
(71, 'mannequin', NULL, NULL, NULL, '2026-01-12 13:55:20'),
(72, 'Rodriguez', NULL, NULL, NULL, '2026-01-12 14:04:34'),
(73, 'Stéphanie kadonia', NULL, NULL, NULL, '2026-01-12 15:50:33'),
(74, 'tayc', NULL, NULL, NULL, '2026-01-12 16:04:40'),
(75, 'un un client du lundi soir', NULL, NULL, NULL, '2026-01-14 08:04:45'),
(76, 'pakimo', NULL, NULL, NULL, '2026-01-14 12:10:57'),
(77, 'makimo', NULL, NULL, NULL, '2026-01-14 12:18:14'),
(78, 'archange', NULL, NULL, NULL, '2026-01-14 15:46:46'),
(79, 'Clovis', NULL, NULL, NULL, '2026-01-15 14:02:43'),
(80, 'bienfaits kombi', NULL, NULL, NULL, '2026-01-15 14:04:34'),
(81, 'p molo', NULL, NULL, NULL, '2026-01-15 14:50:47'),
(82, 'molo', NULL, NULL, NULL, '2026-01-15 14:53:29'),
(83, 'Guy', NULL, NULL, NULL, '2026-01-16 16:13:23'),
(84, 'Daniel', NULL, NULL, NULL, '2026-01-17 10:40:13'),
(85, 'Lajoie', NULL, NULL, NULL, '2026-01-17 11:49:05'),
(86, 'mr Jérôme hier', NULL, NULL, NULL, '2026-01-17 12:01:58'),
(87, 'mr bienfait kombi', NULL, NULL, NULL, '2026-01-17 12:05:38'),
(88, 'hier mr bienfait kombi', NULL, NULL, NULL, '2026-01-17 12:06:04'),
(89, 'Fidel', NULL, NULL, NULL, '2026-01-17 12:37:31'),
(90, 'mr komby', NULL, NULL, NULL, '2026-01-19 09:36:13'),
(91, 'mr Divin', NULL, NULL, NULL, '2026-01-19 09:41:51'),
(92, 'mr fidèle', NULL, NULL, NULL, '2026-01-19 09:49:56'),
(93, 'bene gtb', NULL, NULL, NULL, '2026-01-19 10:52:30'),
(94, 'bene', NULL, NULL, NULL, '2026-01-19 10:53:43');

-- --------------------------------------------------------

--
-- Structure de la table `deposits`
--

CREATE TABLE `deposits` (
  `id` int(11) NOT NULL,
  `client_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `deposit_date` date NOT NULL DEFAULT current_timestamp(),
  `stock_reserved` tinyint(1) NOT NULL DEFAULT 0,
  `sale_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Structure de la table `invoices`
--

CREATE TABLE `invoices` (
  `id` int(11) NOT NULL,
  `sale_id` int(11) DEFAULT NULL,
  `invoice_date` datetime DEFAULT current_timestamp(),
  `amount` decimal(10,2) NOT NULL,
  `status` enum('payée','impayée') DEFAULT 'impayée'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `invoices`
--

INSERT INTO `invoices` (`id`, `sale_id`, `invoice_date`, `amount`, `status`) VALUES
(57, 64, '2026-01-12 12:53:51', 1400.00, 'payée'),
(58, 65, '2026-01-12 13:00:32', 210.00, 'payée'),
(59, 66, '2026-01-12 13:12:35', 1300.00, 'payée'),
(60, 67, '2026-01-12 13:20:23', 490.00, 'payée'),
(61, 68, '2026-01-12 13:23:53', 425.00, 'payée'),
(62, 69, '2026-01-12 13:32:32', 370.00, 'payée'),
(63, 70, '2026-01-12 13:42:46', 380.00, 'payée'),
(64, 71, '2026-01-12 13:48:52', 350.00, 'payée'),
(65, 72, '2026-01-12 13:53:29', 115.00, 'payée'),
(66, 73, '2026-01-12 14:05:16', 100.00, 'payée'),
(67, 74, '2026-01-12 14:09:48', 140.00, 'payée'),
(68, 75, '2026-01-12 14:13:14', 360.00, 'payée'),
(69, 76, '2026-01-12 14:16:53', 570.00, 'payée'),
(70, 77, '2026-01-12 14:23:06', 130.00, 'payée'),
(71, 78, '2026-01-12 14:30:24', 170.00, 'payée'),
(72, 79, '2026-01-12 14:30:53', 140.00, 'payée'),
(73, 80, '2026-01-12 14:33:24', 280.00, 'payée'),
(74, 81, '2026-01-12 14:37:03', 320.00, 'payée'),
(75, 82, '2026-01-12 14:39:20', 340.00, 'payée'),
(76, 83, '2026-01-12 14:41:20', 115.00, 'payée'),
(77, 84, '2026-01-12 14:42:23', 300.00, 'payée'),
(78, 85, '2026-01-12 14:44:23', 140.00, 'payée'),
(79, 86, '2026-01-12 14:46:34', 300.00, 'payée'),
(80, 87, '2026-01-12 14:48:18', 90.00, 'payée'),
(81, 88, '2026-01-12 14:51:27', 160.00, 'payée'),
(82, 89, '2026-01-12 14:53:33', 550.00, 'payée'),
(83, 90, '2026-01-12 14:56:13', 250.00, 'payée'),
(84, 91, '2026-01-12 15:00:25', 75.00, 'payée'),
(85, 92, '2026-01-12 15:07:52', 660.00, 'payée'),
(86, 93, '2026-01-12 16:51:36', 260.00, 'payée'),
(87, 94, '2026-01-12 17:03:37', 70.00, 'payée'),
(88, 95, '2026-01-12 17:06:01', 28.00, 'payée'),
(89, 96, '2026-01-14 09:03:05', 250.00, 'payée'),
(90, 97, '2026-01-14 13:18:46', 990.00, 'payée'),
(91, 98, '2026-01-14 16:47:12', 50.00, 'payée'),
(92, 99, '2026-01-15 15:03:42', 320.00, 'payée'),
(93, 100, '2026-01-15 15:05:58', 330.00, 'payée'),
(94, 101, '2026-01-17 11:42:06', 29.00, 'payée'),
(95, 102, '2026-01-17 12:49:35', 30.00, 'payée'),
(96, 103, '2026-01-17 13:03:09', 2700.00, 'payée'),
(97, 104, '2026-01-17 13:08:15', 620.00, 'payée'),
(98, 105, '2026-01-17 13:12:52', 540.00, 'payée'),
(99, 106, '2026-01-19 10:39:24', 630.00, 'impayée'),
(100, 108, '2026-01-19 10:46:41', 6890.00, 'payée'),
(101, 109, '2026-01-19 10:55:43', 1320.00, 'payée'),
(102, 110, '2026-01-19 11:54:36', 1890.00, 'payée'),
(103, 111, '2026-01-19 11:58:29', 280.00, 'payée'),
(104, 112, '2026-01-19 12:01:11', 280.00, 'payée');

-- --------------------------------------------------------

--
-- Structure de la table `products`
--

CREATE TABLE `products` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `description` text DEFAULT NULL,
  `price` decimal(10,2) NOT NULL,
  `quantity` int(11) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `prix_vente` decimal(10,2) NOT NULL DEFAULT 0.00
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `products`
--

INSERT INTO `products` (`id`, `name`, `description`, `price`, `quantity`, `created_at`, `prix_vente`) VALUES
(565, 'iphone 15 Pro', 'm', 422.00, 1, '2026-01-08 05:35:24', 650.00),
(566, 'Iphone 14plus', 'M', 313.00, 6, '2026-01-08 05:37:13', 400.00),
(567, 'iphone 14pro max', 'M', 422.00, 2, '2026-01-08 05:39:39', 580.00),
(568, 'Iphone 14', 'm', 272.00, 1, '2026-01-08 05:41:23', 400.00),
(569, 'Iphone 13 pro max', 'm', 340.00, 5, '2026-01-08 05:42:43', 500.00),
(570, 'Iphone 13pro', '..', 315.00, 3, '2026-01-08 05:43:39', 400.00),
(571, 'Iphone 13', '..', 220.00, 4, '2026-01-08 05:44:41', 280.00),
(572, 'Iphone 12pro', '.', 232.00, 3, '2026-01-08 05:46:06', 285.00),
(573, 'Xr', '.', 105.00, 2, '2026-01-08 05:47:35', 150.00),
(574, 'Iphone 11pro max', 'us ', 210.00, 13, '2026-01-08 05:48:55', 260.00),
(575, '12pro max', '.', 280.00, 1, '2026-01-08 05:50:42', 350.00),
(576, 'Iphone 12', '.', 167.00, 4, '2026-01-08 05:52:26', 225.00),
(577, 'Fold3', '.', 272.00, 1, '2026-01-08 05:55:13', 350.00),
(578, 'S10plus', 'Big lcd', 61.00, 6, '2026-01-08 05:57:07', 85.00),
(579, 'Samsung s20Fe', '.', 79.00, 0, '2026-01-08 05:58:32', 100.00),
(580, 'Note9', 'samusung', 64.00, 0, '2026-01-08 06:02:36', 85.00),
(581, 'S21plus', 'Samsung', 100.00, 0, '2026-01-08 06:04:42', 135.00),
(582, 'S9', 'samsung', 54.00, 3, '2026-01-08 06:05:24', 80.00),
(583, 'S8plus', 'samsung', 55.00, 1, '2026-01-08 06:06:29', 75.00),
(584, 'pixel 8', 'original', 198.00, 1, '2026-01-08 06:08:19', 220.00),
(585, 'Pixel 8pro', 'Original', 258.00, 1, '2026-01-08 06:11:42', 330.00),
(586, 'Pixel 7', '.', 109.00, 0, '2026-01-08 06:12:46', 140.00),
(587, 'Pixel6a', '.', 94.00, 1, '2026-01-08 06:15:35', 125.00),
(588, 'Pixel6', '.', 100.00, 1, '2026-01-08 06:16:24', 120.00),
(589, 'pixel5a', '.', 75.00, 2, '2026-01-08 06:17:18', 100.00),
(590, 'pixel 2xl', '.', 45.00, 4, '2026-01-08 06:18:00', 50.00),
(591, 'Pixel xl', '.', 40.00, 5, '2026-01-08 06:18:29', 45.00),
(592, 'sence6', '.', 40.00, 2, '2026-01-08 06:31:36', 50.00),
(593, 'Oppo r', '.', 25.00, 2, '2026-01-08 06:32:04', 30.00),
(594, 'Honor', '.', 35.00, 1, '2026-01-08 06:33:24', 40.00),
(595, 'Sony 10iii', '.', 50.00, 3, '2026-01-08 06:34:04', 55.00),
(596, 'sence5', '.', 44.00, 1, '2026-01-08 06:46:06', 45.00),
(597, 'Sony xz5', '.', 25.00, 2, '2026-01-08 06:50:17', 30.00),
(598, 'wikoo', '.', 15.00, 3, '2026-01-11 22:22:02', 20.00),
(599, 'huawei', '.', 18.00, 1, '2026-01-11 22:22:37', 22.00),
(600, 'Arrows', '.', 28.00, 1, '2026-01-11 22:23:17', 35.00),
(601, 'isai', '.', 34.00, 15, '2026-01-11 22:24:08', 36.00),
(602, 'A23', '.', 35.00, 1, '2026-01-11 22:25:01', 40.00),
(603, 'R6', '.', 77.00, 1, '2026-01-11 22:25:39', 80.00),
(604, 'Aqous r1', '.', 43.00, 11, '2026-01-11 22:26:22', 45.00),
(605, 'Aqous r2', '.', 38.00, 3, '2026-01-11 22:27:11', 45.00),
(606, 'Aqous 06', '.', 40.00, 1, '2026-01-11 22:30:33', 45.00),
(607, 'sony 5mini', '.', 20.00, 4, '2026-01-11 22:31:36', 22.00),
(608, 'x compact', '.', 25.00, 7, '2026-01-11 22:33:08', 28.00),
(609, 'lg sytle 2', '.', 50.00, 0, '2026-01-11 22:34:00', 55.00),
(610, 'tablett', '.', 19.00, 14, '2026-01-11 22:35:17', 35.00),
(611, 'redmi9a', '.', 25.00, 1, '2026-01-12 00:39:33', 35.00),
(612, 'xperfomance', '.', 26.00, 11, '2026-01-12 00:40:32', 27.00),
(613, 'xzd5', ' .', 25.00, 8, '2026-01-12 00:41:32', 27.00),
(614, 'wish 2', '.', 40.00, 2, '2026-01-12 00:42:33', 45.00),
(615, 'Iphone 13', 'Us🇺🇲', 220.00, -2, '2026-01-17 03:19:24', 270.00),
(616, 'IPHONE 12 PRO 256 JB', 'US🇺🇲', 233.30, 39, '2026-01-17 03:31:01', 315.00);

-- --------------------------------------------------------

--
-- Structure de la table `sales`
--

CREATE TABLE `sales` (
  `id` int(11) NOT NULL,
  `client_id` int(11) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `sale_date` datetime DEFAULT current_timestamp(),
  `total` decimal(10,2) NOT NULL,
  `imei` varchar(110) NOT NULL,
  `garanti` varchar(110) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `sales`
--

INSERT INTO `sales` (`id`, `client_id`, `user_id`, `sale_date`, `total`, `imei`, `garanti`) VALUES
(64, 61, 1, '2026-01-12 12:53:50', 1400.00, '', ''),
(65, 60, 1, '2026-01-12 13:00:31', 210.00, '', ''),
(66, 62, 1, '2026-01-12 13:12:30', 1300.00, '', ''),
(67, 64, 1, '2026-01-12 13:20:16', 490.00, '', ''),
(68, 61, 1, '2026-01-12 13:23:51', 425.00, '', ''),
(69, 65, 1, '2026-01-12 13:32:31', 370.00, '', ''),
(70, 66, 1, '2026-01-12 13:42:45', 380.00, '', ''),
(71, 60, 1, '2026-01-12 13:48:50', 350.00, '', ''),
(72, 68, 1, '2026-01-12 13:53:28', 115.00, '', ''),
(73, 65, 1, '2026-01-12 14:05:15', 100.00, '', ''),
(74, 65, 1, '2026-01-12 14:09:46', 140.00, '', ''),
(75, 65, 1, '2026-01-12 14:13:13', 360.00, '', ''),
(76, 69, 1, '2026-01-12 14:16:47', 570.00, '', ''),
(77, 69, 1, '2026-01-12 14:23:05', 130.00, '', ''),
(78, 65, 1, '2026-01-12 14:30:23', 170.00, '', ''),
(79, 65, 1, '2026-01-12 14:30:52', 140.00, '', ''),
(80, 65, 1, '2026-01-12 14:33:23', 280.00, '', ''),
(81, 65, 1, '2026-01-12 14:37:02', 320.00, '', ''),
(82, 66, 1, '2026-01-12 14:39:16', 340.00, '', ''),
(83, 59, 1, '2026-01-12 14:41:16', 115.00, '', ''),
(84, 59, 1, '2026-01-12 14:42:22', 300.00, '', ''),
(85, 65, 1, '2026-01-12 14:44:21', 140.00, '', ''),
(86, 59, 1, '2026-01-12 14:46:32', 300.00, '', ''),
(87, 70, 1, '2026-01-12 14:48:15', 90.00, '', ''),
(88, 62, 1, '2026-01-12 14:51:25', 160.00, '', ''),
(89, 65, 1, '2026-01-12 14:53:30', 550.00, '', ''),
(90, 71, 1, '2026-01-12 14:56:12', 250.00, '', ''),
(91, 65, 1, '2026-01-12 15:00:24', 75.00, '', ''),
(92, 72, 1, '2026-01-12 15:07:50', 660.00, '', ''),
(93, 73, 1, '2026-01-12 16:51:35', 260.00, '', ''),
(94, 65, 1, '2026-01-12 17:03:33', 70.00, '', ''),
(95, 74, 1, '2026-01-12 17:06:00', 28.00, '', ''),
(96, 65, 1, '2026-01-14 09:03:04', 250.00, '', ''),
(97, 77, 1, '2026-01-14 13:18:44', 990.00, '', ''),
(98, 78, 1, '2026-01-14 16:47:11', 50.00, '', ''),
(99, 79, 1, '2026-01-15 15:03:40', 320.00, '', ''),
(100, 80, 1, '2026-01-15 15:05:50', 330.00, '', ''),
(101, 84, 1, '2026-01-17 11:42:05', 29.00, '', ''),
(102, 85, 1, '2026-01-17 12:49:34', 30.00, '', ''),
(103, 86, 1, '2026-01-17 13:03:06', 2700.00, '', ''),
(104, 88, 1, '2026-01-17 13:08:14', 620.00, '', ''),
(105, 88, 1, '2026-01-17 13:12:50', 540.00, '', ''),
(106, 90, 1, '2026-01-19 10:39:20', 630.00, '', ''),
(107, 91, 1, '2026-01-19 10:45:33', 6890.00, '', ''),
(108, 91, 1, '2026-01-19 10:46:40', 6890.00, '', ''),
(109, 92, 1, '2026-01-19 10:55:42', 1320.00, '', ''),
(110, 94, 1, '2026-01-19 11:54:35', 1890.00, '', ''),
(111, 89, 1, '2026-01-19 11:58:28', 280.00, '', ''),
(112, 89, 1, '2026-01-19 12:01:09', 280.00, '', '');

-- --------------------------------------------------------

--
-- Structure de la table `sale_details`
--

CREATE TABLE `sale_details` (
  `id` int(11) NOT NULL,
  `sale_id` int(11) DEFAULT NULL,
  `product_id` int(11) DEFAULT NULL,
  `quantity` int(11) NOT NULL,
  `price` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `sale_details`
--

INSERT INTO `sale_details` (`id`, `sale_id`, `product_id`, `quantity`, `price`) VALUES
(64, 64, 578, 20, 70.00),
(65, 65, 578, 3, 70.00),
(66, 66, 565, 2, 650.00),
(67, 67, 578, 7, 70.00),
(68, 68, 580, 5, 85.00),
(69, 69, 570, 1, 370.00),
(70, 70, 569, 1, 380.00),
(71, 71, 578, 5, 70.00),
(72, 72, 581, 1, 115.00),
(73, 73, 589, 1, 100.00),
(74, 74, 578, 2, 70.00),
(75, 75, 570, 1, 360.00),
(76, 76, 567, 1, 570.00),
(77, 77, 573, 1, 130.00),
(78, 78, 578, 2, 85.00),
(79, 79, 578, 2, 70.00),
(80, 80, 586, 2, 140.00),
(81, 81, 585, 1, 320.00),
(82, 82, 570, 1, 340.00),
(83, 83, 587, 1, 115.00),
(84, 84, 575, 1, 300.00),
(85, 85, 586, 1, 140.00),
(86, 86, 575, 1, 300.00),
(87, 87, 579, 1, 90.00),
(88, 88, 578, 2, 80.00),
(89, 89, 567, 1, 550.00),
(90, 90, 574, 1, 250.00),
(91, 91, 578, 1, 75.00),
(92, 92, 585, 2, 330.00),
(93, 93, 574, 1, 260.00),
(94, 94, 578, 1, 70.00),
(95, 95, 612, 1, 28.00),
(96, 96, 574, 1, 250.00),
(97, 97, 609, 18, 55.00),
(98, 98, 612, 2, 25.00),
(99, 99, 585, 1, 320.00),
(100, 100, 585, 1, 330.00),
(101, 101, 601, 1, 29.00),
(102, 102, 601, 1, 30.00),
(103, 103, 615, 10, 270.00),
(104, 104, 616, 2, 310.00),
(105, 105, 615, 2, 270.00),
(106, 106, 616, 2, 315.00),
(107, 107, 616, 7, 290.00),
(108, 107, 615, 18, 270.00),
(109, 108, 616, 7, 290.00),
(110, 108, 615, 18, 270.00),
(111, 109, 616, 2, 280.00),
(112, 109, 574, 2, 245.00),
(113, 109, 573, 2, 135.00),
(114, 110, 616, 6, 315.00),
(115, 111, 571, 1, 280.00),
(116, 112, 571, 1, 280.00);

-- --------------------------------------------------------

--
-- Structure de la table `sorties`
--

CREATE TABLE `sorties` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `montant` decimal(10,2) NOT NULL,
  `motif` varchar(255) NOT NULL,
  `date_sortie` datetime DEFAULT current_timestamp(),
  `type` varchar(110) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `sorties`
--

INSERT INTO `sorties` (`id`, `user_id`, `montant`, `motif`, `date_sortie`, `type`) VALUES
(22, 1, 1.00, 'teste', '2026-01-19 11:18:21', 'normal'),
(23, 1, 1.00, 'test', '2026-01-19 11:18:42', 'transaction');

-- --------------------------------------------------------

--
-- Structure de la table `stock_out_records`
--

CREATE TABLE `stock_out_records` (
  `id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `client_id` int(11) DEFAULT NULL,
  `quantity` int(11) NOT NULL,
  `reason` varchar(255) NOT NULL,
  `out_date` datetime NOT NULL,
  `client_name` varchar(255) DEFAULT NULL,
  `paid_status` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `stock_out_records`
--

INSERT INTO `stock_out_records` (`id`, `product_id`, `client_id`, `quantity`, `reason`, `out_date`, `client_name`, `paid_status`) VALUES
(15, 609, 76, 1, 'Vente', '2026-01-14 13:10:59', NULL, 0);

-- --------------------------------------------------------

--
-- Structure de la table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `username` varchar(50) NOT NULL,
  `password` varchar(255) NOT NULL,
  `role` enum('admin','vendeur','magasinier') NOT NULL DEFAULT 'vendeur',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `users`
--

INSERT INTO `users` (`id`, `username`, `password`, `role`, `created_at`) VALUES
(1, 'admin', '$2y$10$abcdefghijklmnopqrstuv', 'admin', '2025-06-29 14:01:47'),
(2, 'winner', '$2y$10$GIhpl7vYSfk5MAQnVW766uYUcNEbKcr0oDZb1M6y9.EE8wkAarSWC', 'admin', '2025-06-29 14:30:04'),
(3, 'dylan', '0000', 'admin', '2025-06-29 15:01:36'),
(4, 'moise', '1111', 'vendeur', '2025-07-03 17:05:16'),
(5, 'modeste', '1010', 'vendeur', '2025-07-10 14:17:42');

-- --------------------------------------------------------

--
-- Structure de la table `visitor_stats`
--

CREATE TABLE `visitor_stats` (
  `id` int(11) NOT NULL,
  `page_name` varchar(50) DEFAULT NULL,
  `visit_count` int(11) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Déchargement des données de la table `visitor_stats`
--

INSERT INTO `visitor_stats` (`id`, `page_name`, `visit_count`) VALUES
(1, 'promo_page', 15);

--
-- Index pour les tables déchargées
--

--
-- Index pour la table `clients`
--
ALTER TABLE `clients`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `deposits`
--
ALTER TABLE `deposits`
  ADD PRIMARY KEY (`id`),
  ADD KEY `client_id` (`client_id`),
  ADD KEY `product_id` (`product_id`),
  ADD KEY `sale_id` (`sale_id`);

--
-- Index pour la table `invoices`
--
ALTER TABLE `invoices`
  ADD PRIMARY KEY (`id`),
  ADD KEY `sale_id` (`sale_id`);

--
-- Index pour la table `products`
--
ALTER TABLE `products`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `sales`
--
ALTER TABLE `sales`
  ADD PRIMARY KEY (`id`),
  ADD KEY `client_id` (`client_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Index pour la table `sale_details`
--
ALTER TABLE `sale_details`
  ADD PRIMARY KEY (`id`),
  ADD KEY `sale_id` (`sale_id`),
  ADD KEY `product_id` (`product_id`);

--
-- Index pour la table `sorties`
--
ALTER TABLE `sorties`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Index pour la table `stock_out_records`
--
ALTER TABLE `stock_out_records`
  ADD PRIMARY KEY (`id`),
  ADD KEY `product_id` (`product_id`),
  ADD KEY `client_id` (`client_id`);

--
-- Index pour la table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`);

--
-- Index pour la table `visitor_stats`
--
ALTER TABLE `visitor_stats`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `page_name` (`page_name`);

--
-- AUTO_INCREMENT pour les tables déchargées
--

--
-- AUTO_INCREMENT pour la table `clients`
--
ALTER TABLE `clients`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=95;

--
-- AUTO_INCREMENT pour la table `deposits`
--
ALTER TABLE `deposits`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT pour la table `invoices`
--
ALTER TABLE `invoices`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=105;

--
-- AUTO_INCREMENT pour la table `products`
--
ALTER TABLE `products`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=617;

--
-- AUTO_INCREMENT pour la table `sales`
--
ALTER TABLE `sales`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=113;

--
-- AUTO_INCREMENT pour la table `sale_details`
--
ALTER TABLE `sale_details`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=117;

--
-- AUTO_INCREMENT pour la table `sorties`
--
ALTER TABLE `sorties`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=24;

--
-- AUTO_INCREMENT pour la table `stock_out_records`
--
ALTER TABLE `stock_out_records`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT pour la table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT pour la table `visitor_stats`
--
ALTER TABLE `visitor_stats`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- Contraintes pour les tables déchargées
--

--
-- Contraintes pour la table `deposits`
--
ALTER TABLE `deposits`
  ADD CONSTRAINT `deposits_ibfk_1` FOREIGN KEY (`client_id`) REFERENCES `clients` (`id`),
  ADD CONSTRAINT `deposits_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`),
  ADD CONSTRAINT `deposits_ibfk_3` FOREIGN KEY (`sale_id`) REFERENCES `sales` (`id`) ON DELETE SET NULL;

--
-- Contraintes pour la table `invoices`
--
ALTER TABLE `invoices`
  ADD CONSTRAINT `invoices_ibfk_1` FOREIGN KEY (`sale_id`) REFERENCES `sales` (`id`);

--
-- Contraintes pour la table `sales`
--
ALTER TABLE `sales`
  ADD CONSTRAINT `sales_ibfk_1` FOREIGN KEY (`client_id`) REFERENCES `clients` (`id`),
  ADD CONSTRAINT `sales_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

--
-- Contraintes pour la table `sale_details`
--
ALTER TABLE `sale_details`
  ADD CONSTRAINT `fk_sale_details_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`),
  ADD CONSTRAINT `sale_details_ibfk_1` FOREIGN KEY (`sale_id`) REFERENCES `sales` (`id`);

--
-- Contraintes pour la table `sorties`
--
ALTER TABLE `sorties`
  ADD CONSTRAINT `sorties_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
