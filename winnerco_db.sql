-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Hôte : localhost:3306
-- Généré le : mar. 23 déc. 2025 à 13:13
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
(20, 'kenzo', NULL, NULL, NULL, '2025-08-25 12:54:48'),
(21, 'kenzo', NULL, NULL, NULL, '2025-08-25 12:56:20'),
(22, 'dk', NULL, NULL, NULL, '2025-08-25 13:00:42'),
(23, 'dk', NULL, NULL, NULL, '2025-08-25 13:00:43'),
(24, 'kisumba', NULL, NULL, NULL, '2025-08-25 13:00:55'),
(25, 'david', NULL, NULL, NULL, '2025-08-26 09:32:37'),
(26, 'victoire', NULL, NULL, NULL, '2025-08-28 09:32:01'),
(27, 'Daniel musavuli', NULL, NULL, NULL, '2025-09-08 09:23:28'),
(28, 'fiston', NULL, NULL, NULL, '2025-09-08 11:16:39'),
(29, 'papa katsipa', NULL, NULL, NULL, '2025-09-08 11:24:25'),
(30, 'Elaka', NULL, NULL, NULL, '2025-09-08 13:54:01'),
(31, 'frère enock', NULL, NULL, NULL, '2025-09-08 14:34:37'),
(32, 'modeste', NULL, NULL, NULL, '2025-09-08 21:09:46'),
(33, 'elonga', NULL, NULL, NULL, '2025-09-08 21:19:03'),
(34, 'elonga', NULL, NULL, NULL, '2025-09-08 21:19:05'),
(35, 'Moïses', NULL, NULL, NULL, '2025-09-08 21:19:54'),
(36, 'Moïse', NULL, NULL, NULL, '2025-09-08 21:40:28'),
(37, 'Moïse', NULL, NULL, NULL, '2025-09-08 21:40:29'),
(38, 'benjamin kisunga', NULL, NULL, NULL, '2025-09-09 07:23:57'),
(39, 'Jean marie', NULL, NULL, NULL, '2025-09-09 11:18:02'),
(40, 'winner', NULL, NULL, NULL, '2025-09-09 16:31:28'),
(41, 'Jacques', NULL, NULL, NULL, '2025-09-10 08:11:55'),
(42, 'Dylan', NULL, NULL, NULL, '2025-09-10 08:16:16'),
(43, 'Justin', NULL, NULL, NULL, '2025-09-10 14:49:50'),
(44, 'Jérémie', NULL, NULL, NULL, '2025-09-13 08:57:57'),
(45, 'jo', NULL, NULL, NULL, '2025-09-17 09:19:29'),
(46, 'bienfait', NULL, NULL, NULL, '2025-09-17 09:59:47'),
(47, 'kavusa', NULL, NULL, NULL, '2025-09-17 10:00:07'),
(48, 'digne kavira', NULL, NULL, NULL, '2025-10-13 15:44:01'),
(49, 'chrétien', NULL, NULL, NULL, '2025-10-13 15:46:15'),
(50, 'dd', NULL, NULL, NULL, '2025-11-09 07:48:19'),
(51, 'papa kauthura', NULL, NULL, NULL, '2025-12-01 07:13:39'),
(52, 'papa kauthura', NULL, NULL, NULL, '2025-12-01 13:17:35'),
(53, 'bless', NULL, NULL, NULL, '2025-12-01 13:19:14'),
(54, 'Achille', NULL, NULL, NULL, '2025-12-01 13:31:34'),
(55, 'Rodriguez', NULL, NULL, NULL, '2025-12-01 13:36:25'),
(56, 'bless', NULL, NULL, NULL, '2025-12-01 13:43:35'),
(57, 'cela', NULL, NULL, NULL, '2025-12-01 15:08:01');

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
  `stock_reserved` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
(2, 'winner', '0000', 'admin', '2025-06-29 14:30:04'),
(3, 'dylan', '$2y$10$yTpTuS3Qz8HcfXF16GZPduMXFHgEFWOFY4I0whZ1zqJjUcvTN9PTS', 'vendeur', '2025-06-29 15:01:36'),
(4, 'moise', '1111', 'vendeur', '2025-07-03 17:05:16'),
(5, 'modeste', '1010', 'vendeur', '2025-07-10 14:17:42');

--
-- Index pour les tables déchargées
--

--
-- Index pour la table `clients`
--
ALTER TABLE `clients`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uniq_client_name` (`name`);

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
-- Index pour la table `deposits`
--
ALTER TABLE `deposits`
  ADD PRIMARY KEY (`id`),
  ADD KEY `client_id` (`client_id`),
  ADD KEY `product_id` (`product_id`);

--
-- Index pour la table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`);

--
-- AUTO_INCREMENT pour les tables déchargées
--

--
-- AUTO_INCREMENT pour la table `clients`
--
ALTER TABLE `clients`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=58;

--
-- AUTO_INCREMENT pour la table `invoices`
--
ALTER TABLE `invoices`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=56;

--
-- AUTO_INCREMENT pour la table `products`
--
ALTER TABLE `products`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=563;

--
-- AUTO_INCREMENT pour la table `sales`
--
ALTER TABLE `sales`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=61;

--
-- AUTO_INCREMENT pour la table `sale_details`
--
ALTER TABLE `sale_details`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=61;

--
-- AUTO_INCREMENT pour la table `sorties`
--
ALTER TABLE `sorties`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=20;

--
-- AUTO_INCREMENT pour la table `stock_out_records`
--
ALTER TABLE `stock_out_records`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT pour la table `deposits`
--
ALTER TABLE `deposits`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1;

--
-- AUTO_INCREMENT pour la table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- Contraintes pour les tables déchargées
--

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

--
-- Contraintes pour la table `deposits`
--
ALTER TABLE `deposits`
  ADD CONSTRAINT `deposits_ibfk_1` FOREIGN KEY (`client_id`) REFERENCES `clients` (`id`),
  ADD CONSTRAINT `deposits_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
