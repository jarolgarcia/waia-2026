-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 09-10-2026 a las 09:42:59
-- Versión del servidor: 10.4.32-MariaDB
-- Versión de PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `waia`
--

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `artisans`
--

CREATE TABLE `artisans` (
  `id` int(10) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED DEFAULT NULL,
  `community_id` int(10) UNSIGNED DEFAULT NULL,
  `name` varchar(150) NOT NULL,
  `specialty` varchar(150) DEFAULT NULL,
  `biography` text DEFAULT NULL,
  `profile_image` varchar(500) DEFAULT NULL,
  `phone` varchar(30) DEFAULT NULL,
  `email` varchar(150) DEFAULT NULL,
  `years_experience` int(10) UNSIGNED DEFAULT 0,
  `verified` tinyint(1) NOT NULL DEFAULT 0,
  `status` enum('active','inactive') NOT NULL DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `auth_login_rate_limits`
--

CREATE TABLE `auth_login_rate_limits` (
  `email_hash` char(64) NOT NULL,
  `failure_count` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `first_failure_at` datetime NOT NULL,
  `blocked_until` datetime DEFAULT NULL,
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `auth_login_rate_limits`
--

INSERT INTO `auth_login_rate_limits` (`email_hash`, `failure_count`, `first_failure_at`, `blocked_until`, `updated_at`) VALUES
('539f4c099e606ee8153db27a3ad2603345896f3e18cc6569010d1364d0e06acd', 7, '2026-10-09 05:21:40', '2026-10-09 05:36:50', '2026-10-09 05:21:50'),
('61d7c574e605394525c91526291a38363544b5a41dbbec3ee6c6a883cffb1d96', 7, '2026-10-09 05:22:00', '2026-10-09 05:37:02', '2026-10-09 05:22:02'),
('804e2f16a2607e50db13943826f447775128406f946aebf8264f07b82e7cb27f', 5, '2026-10-09 05:42:06', '2026-10-09 05:47:08', '2026-10-09 05:42:08'),
('d16ce9fa4cc1ca4ce4506d2d829a86fd13199bb72fce434ed763f142db57d852', 5, '2026-10-09 05:22:16', '2026-10-09 05:37:17', '2026-10-09 05:22:17'),
('db8321897a8b560d87254b67530d450a5df1760465868132729d4ad110e970d7', 1, '2026-10-09 05:21:36', NULL, '2026-10-09 05:21:36'),
('e8351f627c1a63a53efaa13134a7a8284182a7d872be39ce7723cb1f32332213', 5, '2026-10-09 05:22:43', '2026-10-09 05:37:44', '2026-10-09 05:22:44'),
('ebf99bf668f64d866db620f9e7573e9d58b8a8d62dba3981005db22c89eb2f54', 1, '2026-10-09 05:43:07', NULL, '2026-10-09 05:43:07');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `bookings`
--

CREATE TABLE `bookings` (
  `id` int(10) UNSIGNED NOT NULL,
  `booking_code` varchar(50) NOT NULL,
  `user_id` int(10) UNSIGNED DEFAULT NULL,
  `experience_id` int(10) UNSIGNED NOT NULL,
  `booking_date` date NOT NULL,
  `booking_time` time DEFAULT NULL,
  `participants` int(10) UNSIGNED NOT NULL DEFAULT 1,
  `customer_name` varchar(200) NOT NULL,
  `customer_email` varchar(150) NOT NULL,
  `customer_phone` varchar(30) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `price_per_person_nio` decimal(10,2) DEFAULT 0.00,
  `price_per_person_usd` decimal(10,2) DEFAULT 0.00,
  `total_nio` decimal(10,2) DEFAULT 0.00,
  `total_usd` decimal(10,2) DEFAULT 0.00,
  `currency` enum('NIO','USD') NOT NULL DEFAULT 'NIO',
  `status` enum('pending','confirmed','cancelled','completed') NOT NULL DEFAULT 'pending',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `categories`
--

CREATE TABLE `categories` (
  `id` int(10) UNSIGNED NOT NULL,
  `name` varchar(100) NOT NULL,
  `slug` varchar(120) NOT NULL,
  `description` text DEFAULT NULL,
  `icon` varchar(100) DEFAULT NULL,
  `status` enum('active','inactive') NOT NULL DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `categories`
--

INSERT INTO `categories` (`id`, `name`, `slug`, `description`, `icon`, `status`, `created_at`, `updated_at`) VALUES
(1, 'Gastronomía', 'gastronomia', 'Experiencias gastronómicas y sabores tradicionales de Nicaragua.', 'restaurant', 'active', '2026-10-08 21:44:41', '2026-10-08 21:44:41'),
(2, 'Artesanía', 'artesania', 'Experiencias relacionadas con artesanía, arte y producción local.', 'palette', 'active', '2026-10-08 21:44:41', '2026-10-08 21:44:41'),
(3, 'Mitos e Historias', 'mitos-e-historias', 'Historias, leyendas, tradiciones y patrimonio cultural.', 'auto_stories', 'active', '2026-10-08 21:44:41', '2026-10-08 21:44:41'),
(4, 'Naturaleza y Aventura', 'naturaleza-y-aventura', 'Experiencias de naturaleza, aventura y exploración.', 'landscape', 'active', '2026-10-08 21:44:41', '2026-10-08 21:44:41');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `communities`
--

CREATE TABLE `communities` (
  `id` int(10) UNSIGNED NOT NULL,
  `name` varchar(150) NOT NULL,
  `slug` varchar(180) NOT NULL,
  `description` text DEFAULT NULL,
  `short_description` varchar(500) DEFAULT NULL,
  `department_id` int(10) UNSIGNED DEFAULT NULL,
  `image_url` varchar(500) DEFAULT NULL,
  `latitude` decimal(10,7) DEFAULT NULL,
  `longitude` decimal(10,7) DEFAULT NULL,
  `contact_phone` varchar(30) DEFAULT NULL,
  `contact_email` varchar(150) DEFAULT NULL,
  `website` varchar(255) DEFAULT NULL,
  `status` enum('active','inactive') NOT NULL DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `contact_messages`
--

CREATE TABLE `contact_messages` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(180) NOT NULL,
  `email` varchar(190) NOT NULL,
  `subject` varchar(250) DEFAULT NULL,
  `message` text NOT NULL,
  `status` enum('new','read','resolved') NOT NULL DEFAULT 'new',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `departments`
--

CREATE TABLE `departments` (
  `id` int(10) UNSIGNED NOT NULL,
  `name` varchar(100) NOT NULL,
  `slug` varchar(120) NOT NULL,
  `description` text DEFAULT NULL,
  `short_description` varchar(500) DEFAULT NULL,
  `capital` varchar(100) DEFAULT NULL,
  `image_url` varchar(500) DEFAULT NULL,
  `latitude` decimal(10,7) DEFAULT NULL,
  `longitude` decimal(10,7) DEFAULT NULL,
  `status` enum('active','inactive') NOT NULL DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `departments`
--

INSERT INTO `departments` (`id`, `name`, `slug`, `description`, `short_description`, `capital`, `image_url`, `latitude`, `longitude`, `status`, `created_at`, `updated_at`) VALUES
(1, 'Boaco', 'boaco', NULL, NULL, 'Boaco', NULL, NULL, NULL, 'active', '2026-10-08 21:45:00', '2026-10-08 21:45:00'),
(2, 'Carazo', 'carazo', NULL, NULL, 'Jinotepe', NULL, NULL, NULL, 'active', '2026-10-08 21:45:00', '2026-10-08 21:45:00'),
(3, 'Chinandega', 'chinandega', NULL, NULL, 'Chinandega', NULL, NULL, NULL, 'active', '2026-10-08 21:45:00', '2026-10-08 21:45:00'),
(4, 'Chontales', 'chontales', NULL, NULL, 'Juigalpa', NULL, NULL, NULL, 'active', '2026-10-08 21:45:00', '2026-10-08 21:45:00'),
(5, 'Estelí', 'esteli', NULL, NULL, 'Estelí', NULL, NULL, NULL, 'active', '2026-10-08 21:45:00', '2026-10-08 21:45:00'),
(6, 'Granada', 'granada', NULL, NULL, 'Granada', NULL, NULL, NULL, 'active', '2026-10-08 21:45:00', '2026-10-08 21:45:00'),
(7, 'Jinotega', 'jinotega', NULL, NULL, 'Jinotega', NULL, NULL, NULL, 'active', '2026-10-08 21:45:00', '2026-10-08 21:45:00'),
(8, 'León', 'leon', NULL, NULL, 'León', NULL, NULL, NULL, 'active', '2026-10-08 21:45:00', '2026-10-08 21:45:00'),
(9, 'Madriz', 'madriz', NULL, NULL, 'Somoto', NULL, NULL, NULL, 'active', '2026-10-08 21:45:00', '2026-10-08 21:45:00'),
(10, 'Managua', 'managua', NULL, NULL, 'Managua', NULL, NULL, NULL, 'active', '2026-10-08 21:45:00', '2026-10-08 21:45:00'),
(11, 'Masaya', 'masaya', NULL, NULL, 'Masaya', NULL, NULL, NULL, 'active', '2026-10-08 21:45:00', '2026-10-08 21:45:00'),
(12, 'Matagalpa', 'matagalpa', NULL, NULL, 'Matagalpa', NULL, NULL, NULL, 'active', '2026-10-08 21:45:00', '2026-10-08 21:45:00'),
(13, 'Nueva Segovia', 'nueva-segovia', NULL, NULL, 'Ocotal', NULL, NULL, NULL, 'active', '2026-10-08 21:45:00', '2026-10-08 21:45:00'),
(14, 'Río San Juan', 'rio-san-juan', NULL, NULL, 'San Carlos', NULL, NULL, NULL, 'active', '2026-10-08 21:45:00', '2026-10-08 21:45:00'),
(15, 'Rivas', 'rivas', NULL, NULL, 'Rivas', NULL, NULL, NULL, 'active', '2026-10-08 21:45:00', '2026-10-08 21:45:00'),
(16, 'Región Autónoma de la Costa Caribe Norte', 'racn', NULL, NULL, 'Puerto Cabezas', NULL, NULL, NULL, 'active', '2026-10-08 21:45:00', '2026-10-08 21:45:00'),
(17, 'Región Autónoma de la Costa Caribe Sur', 'raccs', NULL, NULL, 'Bluefields', NULL, NULL, NULL, 'active', '2026-10-08 21:45:00', '2026-10-08 21:45:00');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `experiences`
--

CREATE TABLE `experiences` (
  `id` int(10) UNSIGNED NOT NULL,
  `title` varchar(200) NOT NULL,
  `slug` varchar(220) NOT NULL,
  `category_id` int(10) UNSIGNED NOT NULL,
  `department_id` int(10) UNSIGNED NOT NULL,
  `community_id` int(10) UNSIGNED DEFAULT NULL,
  `host_id` int(10) UNSIGNED DEFAULT NULL,
  `artisan_id` int(10) UNSIGNED DEFAULT NULL,
  `location` varchar(200) NOT NULL,
  `short_description` varchar(500) NOT NULL,
  `long_description` text DEFAULT NULL,
  `duration_minutes` int(10) UNSIGNED DEFAULT NULL,
  `max_participants` int(10) UNSIGNED DEFAULT NULL,
  `difficulty` enum('easy','moderate','difficult') DEFAULT 'easy',
  `price_nio` decimal(10,2) NOT NULL DEFAULT 0.00,
  `price_usd` decimal(10,2) NOT NULL DEFAULT 0.00,
  `currency_primary` enum('NIO','USD') NOT NULL DEFAULT 'NIO',
  `latitude` decimal(10,7) DEFAULT NULL,
  `longitude` decimal(10,7) DEFAULT NULL,
  `main_image_url` varchar(500) DEFAULT NULL,
  `requirements` text DEFAULT NULL,
  `includes` text DEFAULT NULL,
  `recommendations` text DEFAULT NULL,
  `status` enum('draft','published','inactive') NOT NULL DEFAULT 'draft',
  `featured` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `experiences`
--

INSERT INTO `experiences` (`id`, `title`, `slug`, `category_id`, `department_id`, `community_id`, `host_id`, `artisan_id`, `location`, `short_description`, `long_description`, `duration_minutes`, `max_participants`, `difficulty`, `price_nio`, `price_usd`, `currency_primary`, `latitude`, `longitude`, `main_image_url`, `requirements`, `includes`, `recommendations`, `status`, `featured`, `created_at`, `updated_at`) VALUES
(1, 'jarron', 'jarron-c9877e', 1, 1, NULL, 2, NULL, 'león', 'jarrones de barros', 'jajajajaja', 1, 10, 'easy', 0.00, 55.00, 'USD', NULL, NULL, NULL, NULL, NULL, NULL, 'published', 0, '2026-10-09 02:37:44', '2026-10-09 02:37:44');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `experience_images`
--

CREATE TABLE `experience_images` (
  `id` int(10) UNSIGNED NOT NULL,
  `experience_id` int(10) UNSIGNED NOT NULL,
  `image_url` varchar(500) NOT NULL,
  `alt_text` varchar(255) DEFAULT NULL,
  `display_order` int(10) UNSIGNED DEFAULT 0,
  `is_cover` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `favorites`
--

CREATE TABLE `favorites` (
  `id` int(10) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `experience_id` int(10) UNSIGNED NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `hosts`
--

CREATE TABLE `hosts` (
  `id` int(10) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED DEFAULT NULL,
  `name` varchar(150) NOT NULL,
  `bio` text DEFAULT NULL,
  `profile_image` varchar(500) DEFAULT NULL,
  `phone` varchar(30) DEFAULT NULL,
  `email` varchar(150) DEFAULT NULL,
  `experience_years` int(10) UNSIGNED DEFAULT 0,
  `verified` tinyint(1) NOT NULL DEFAULT 0,
  `status` enum('active','inactive') NOT NULL DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `hosts`
--

INSERT INTO `hosts` (`id`, `user_id`, `name`, `bio`, `profile_image`, `phone`, `email`, `experience_years`, `verified`, `status`, `created_at`, `updated_at`) VALUES
(2, 5, 'carlos Davila', NULL, NULL, NULL, 'davilaaragoncarlos6@gmail.com', 0, 0, 'active', '2026-10-09 02:36:07', '2026-10-09 02:36:07');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `itineraries`
--

CREATE TABLE `itineraries` (
  `id` char(36) NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `name` varchar(180) NOT NULL DEFAULT 'Mi viaje',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `itinerary_items`
--

CREATE TABLE `itinerary_items` (
  `id` char(36) NOT NULL,
  `itinerary_id` char(36) NOT NULL,
  `experience_id` int(10) UNSIGNED NOT NULL,
  `planned_date` date DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `position` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `municipalities`
--

CREATE TABLE `municipalities` (
  `id` int(10) UNSIGNED NOT NULL,
  `department_id` int(10) UNSIGNED NOT NULL,
  `name` varchar(150) NOT NULL,
  `slug` varchar(180) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `reviews`
--

CREATE TABLE `reviews` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `experience_id` int(10) UNSIGNED NOT NULL,
  `rating` tinyint(3) UNSIGNED NOT NULL,
  `title` varchar(200) DEFAULT NULL,
  `comment` text DEFAULT NULL,
  `status` enum('pending','published','hidden') NOT NULL DEFAULT 'pending',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `sync_operations`
--

CREATE TABLE `sync_operations` (
  `operation_id` char(36) NOT NULL,
  `device_id` varchar(100) NOT NULL,
  `scope_key` varchar(190) NOT NULL,
  `received_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `sync_records`
--

CREATE TABLE `sync_records` (
  `id` char(36) NOT NULL,
  `scope_key` varchar(190) NOT NULL,
  `device_id` varchar(100) NOT NULL,
  `entity` varchar(80) NOT NULL,
  `record_id` varchar(190) NOT NULL,
  `action` enum('create','update','upsert','delete') NOT NULL DEFAULT 'upsert',
  `version` bigint(20) UNSIGNED NOT NULL DEFAULT 1,
  `payload` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`payload`)),
  `checksum` char(64) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `users`
--

CREATE TABLE `users` (
  `id` int(10) UNSIGNED NOT NULL,
  `first_name` varchar(100) NOT NULL,
  `last_name` varchar(100) NOT NULL,
  `email` varchar(150) NOT NULL,
  `password` varchar(255) DEFAULT NULL,
  `phone` varchar(30) DEFAULT NULL,
  `country` varchar(100) DEFAULT 'Nicaragua',
  `profile_image` varchar(500) DEFAULT NULL,
  `role` enum('user','host','admin') NOT NULL DEFAULT 'user',
  `status` enum('active','inactive','blocked') NOT NULL DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `users`
--

INSERT INTO `users` (`id`, `first_name`, `last_name`, `email`, `password`, `phone`, `country`, `profile_image`, `role`, `status`, `created_at`, `updated_at`) VALUES
(1, 'jsrol', '', 'jarolg997@gmail.com', '$2y$10$JKh7jwo2Pk3CKpdy/gVZVODrpLOih9HvdjDQw8H94p2d15r/geqQe', NULL, 'Nicaragua', NULL, 'user', 'active', '2026-10-08 23:58:13', '2026-10-08 23:58:13'),
(2, 'Codex', 'Test', 'codex.test.1791506756@example.com', '$2y$10$Q0s3lf3x8KloLl9Gy0aXb.JYNlep0iv5SRwJ1pvN9HXSdoqb8zKB2', NULL, 'Nicaragua', NULL, 'user', 'active', '2026-10-09 00:45:56', '2026-10-09 00:45:56'),
(3, 'Codex', 'Test', 'codex.1791506782@example.com', '$2y$10$CI4ySZTrymy3d2Bs..aUo.mrkCLB2kHgQaYqrm3MuJfG3aMpwPCvS', NULL, 'Nicaragua', NULL, 'user', 'active', '2026-10-09 00:46:22', '2026-10-09 00:46:22'),
(5, 'carlos', 'Davila', 'davilaaragoncarlos6@gmail.com', '$2y$10$noudyXzlB1trDpaGjDon6u5bK5Xtc3RGBVqmfJI/wZcuz/BEi2XQe', NULL, 'Nicaragua', NULL, 'host', 'active', '2026-10-09 02:17:09', '2026-10-09 02:17:09');

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `artisans`
--
ALTER TABLE `artisans`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_artisans_user` (`user_id`),
  ADD KEY `idx_artisans_community` (`community_id`);

--
-- Indices de la tabla `auth_login_rate_limits`
--
ALTER TABLE `auth_login_rate_limits`
  ADD PRIMARY KEY (`email_hash`),
  ADD KEY `idx_auth_login_blocked_until` (`blocked_until`);

--
-- Indices de la tabla `bookings`
--
ALTER TABLE `bookings`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `booking_code` (`booking_code`),
  ADD KEY `idx_bookings_experience` (`experience_id`),
  ADD KEY `idx_bookings_user` (`user_id`),
  ADD KEY `idx_bookings_status` (`status`),
  ADD KEY `idx_bookings_date` (`booking_date`);

--
-- Indices de la tabla `categories`
--
ALTER TABLE `categories`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `name` (`name`),
  ADD UNIQUE KEY `slug` (`slug`);

--
-- Indices de la tabla `communities`
--
ALTER TABLE `communities`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `slug` (`slug`),
  ADD KEY `idx_communities_department` (`department_id`);

--
-- Indices de la tabla `contact_messages`
--
ALTER TABLE `contact_messages`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `departments`
--
ALTER TABLE `departments`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `name` (`name`),
  ADD UNIQUE KEY `slug` (`slug`);

--
-- Indices de la tabla `experiences`
--
ALTER TABLE `experiences`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `slug` (`slug`),
  ADD KEY `idx_experiences_category` (`category_id`),
  ADD KEY `idx_experiences_department` (`department_id`),
  ADD KEY `idx_experiences_community` (`community_id`),
  ADD KEY `idx_experiences_host` (`host_id`),
  ADD KEY `idx_experiences_artisan` (`artisan_id`),
  ADD KEY `idx_experiences_status` (`status`),
  ADD KEY `idx_experiences_featured` (`featured`),
  ADD KEY `idx_experiences_location` (`location`);

--
-- Indices de la tabla `experience_images`
--
ALTER TABLE `experience_images`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_experience_images_experience` (`experience_id`);

--
-- Indices de la tabla `favorites`
--
ALTER TABLE `favorites`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_user_experience` (`user_id`,`experience_id`),
  ADD KEY `fk_favorites_experience` (`experience_id`);

--
-- Indices de la tabla `hosts`
--
ALTER TABLE `hosts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_hosts_user` (`user_id`);

--
-- Indices de la tabla `itineraries`
--
ALTER TABLE `itineraries`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indices de la tabla `itinerary_items`
--
ALTER TABLE `itinerary_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `itinerary_id` (`itinerary_id`),
  ADD KEY `experience_id` (`experience_id`);

--
-- Indices de la tabla `municipalities`
--
ALTER TABLE `municipalities`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_municipality_department_slug` (`department_id`,`slug`);

--
-- Indices de la tabla `reviews`
--
ALTER TABLE `reviews`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `experience_id` (`experience_id`);

--
-- Indices de la tabla `sync_operations`
--
ALTER TABLE `sync_operations`
  ADD PRIMARY KEY (`operation_id`);

--
-- Indices de la tabla `sync_records`
--
ALTER TABLE `sync_records`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_sync_scope_entity_record` (`scope_key`,`entity`,`record_id`),
  ADD KEY `idx_sync_scope_version` (`scope_key`,`version`),
  ADD KEY `idx_sync_device` (`device_id`),
  ADD KEY `idx_sync_updated` (`updated_at`);

--
-- Indices de la tabla `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `artisans`
--
ALTER TABLE `artisans`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `bookings`
--
ALTER TABLE `bookings`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `categories`
--
ALTER TABLE `categories`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `communities`
--
ALTER TABLE `communities`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `contact_messages`
--
ALTER TABLE `contact_messages`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `departments`
--
ALTER TABLE `departments`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- AUTO_INCREMENT de la tabla `experiences`
--
ALTER TABLE `experiences`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla `experience_images`
--
ALTER TABLE `experience_images`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `favorites`
--
ALTER TABLE `favorites`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `hosts`
--
ALTER TABLE `hosts`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `municipalities`
--
ALTER TABLE `municipalities`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `reviews`
--
ALTER TABLE `reviews`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `users`
--
ALTER TABLE `users`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `artisans`
--
ALTER TABLE `artisans`
  ADD CONSTRAINT `fk_artisans_community` FOREIGN KEY (`community_id`) REFERENCES `communities` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_artisans_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Filtros para la tabla `bookings`
--
ALTER TABLE `bookings`
  ADD CONSTRAINT `fk_bookings_experience` FOREIGN KEY (`experience_id`) REFERENCES `experiences` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_bookings_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Filtros para la tabla `communities`
--
ALTER TABLE `communities`
  ADD CONSTRAINT `fk_communities_department` FOREIGN KEY (`department_id`) REFERENCES `departments` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Filtros para la tabla `experiences`
--
ALTER TABLE `experiences`
  ADD CONSTRAINT `fk_experiences_artisan` FOREIGN KEY (`artisan_id`) REFERENCES `artisans` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_experiences_category` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_experiences_community` FOREIGN KEY (`community_id`) REFERENCES `communities` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_experiences_department` FOREIGN KEY (`department_id`) REFERENCES `departments` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_experiences_host` FOREIGN KEY (`host_id`) REFERENCES `hosts` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Filtros para la tabla `experience_images`
--
ALTER TABLE `experience_images`
  ADD CONSTRAINT `fk_experience_images_experience` FOREIGN KEY (`experience_id`) REFERENCES `experiences` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `favorites`
--
ALTER TABLE `favorites`
  ADD CONSTRAINT `fk_favorites_experience` FOREIGN KEY (`experience_id`) REFERENCES `experiences` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_favorites_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `hosts`
--
ALTER TABLE `hosts`
  ADD CONSTRAINT `fk_hosts_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Filtros para la tabla `itineraries`
--
ALTER TABLE `itineraries`
  ADD CONSTRAINT `itineraries_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

--
-- Filtros para la tabla `itinerary_items`
--
ALTER TABLE `itinerary_items`
  ADD CONSTRAINT `itinerary_items_ibfk_1` FOREIGN KEY (`itinerary_id`) REFERENCES `itineraries` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `itinerary_items_ibfk_2` FOREIGN KEY (`experience_id`) REFERENCES `experiences` (`id`);

--
-- Filtros para la tabla `municipalities`
--
ALTER TABLE `municipalities`
  ADD CONSTRAINT `municipalities_ibfk_1` FOREIGN KEY (`department_id`) REFERENCES `departments` (`id`);

--
-- Filtros para la tabla `reviews`
--
ALTER TABLE `reviews`
  ADD CONSTRAINT `reviews_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `reviews_ibfk_2` FOREIGN KEY (`experience_id`) REFERENCES `experiences` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
