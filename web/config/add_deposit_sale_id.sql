-- Script pour ajouter le champ sale_id à la table deposits
-- Ce champ permettra de marquer les dépôts comme utilisés lors de la création d'une vente

ALTER TABLE `deposits` 
ADD COLUMN `sale_id` INT(11) NULL DEFAULT NULL AFTER `stock_reserved`,
ADD KEY `sale_id` (`sale_id`),
ADD CONSTRAINT `deposits_ibfk_3` FOREIGN KEY (`sale_id`) REFERENCES `sales` (`id`) ON DELETE SET NULL;

