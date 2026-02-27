-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
--

local map = vim.keymap.set

-- ========================================
-- Insert 모드
-- ========================================

map("i", "jk", "<ESC>", { desc = "Exit insert mode" })

-- ========================================
-- 버퍼 이동 (여러 파일 작업 시 필수)
-- ========================================
-- deployment.yaml → service.yaml → ingress.yaml 사이를 H, L로 이동

map("n", "H", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
map("n", "L", "<cmd>bnext<cr>", { desc = "Next buffer" })

-- ========================================
-- 들여쓰기 (Visual 모드에서 선택 유지)
-- ========================================
-- 기본 > < 는 들여쓰기 후 선택이 해제됨
-- YAML 블록 들여쓰기를 반복해서 조정할 때 필수

map("v", "<", "<gv", { desc = "Indent left (keep selection)" })
map("v", ">", ">gv", { desc = "Indent right (keep selection)" })

-- ========================================
-- 검색 결과 화면 중앙 유지
-- ========================================

map("n", "n", "nzzzv", { desc = "Next search result (centered)" })
map("n", "N", "Nzzzv", { desc = "Prev search result (centered)" })

-- ========================================
-- 라인 합치기 (커서 위치 유지)
-- ========================================

map("n", "J", "mzJ`z", { desc = "Join lines (keep cursor)" })

-- ========================================
-- 전체 선택
-- ========================================

map("n", "<leader>a", "ggVG", { desc = "Select all" })

-- ========================================
-- 비주얼 모드에서 붙여넣기 시 레지스터 유지
-- ========================================
-- 선택 영역을 교체할 때 원본이 레지스터에서 사라지지 않음

map("v", "p", '"_dP', { desc = "Paste without overwriting register" })
