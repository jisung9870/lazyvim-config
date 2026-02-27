-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- lazyvim default는 conform.setup({ format_on_save = ... })로 되어 있음
-- 여기에 markdown 제외 옵션을 추가

local opt = vim.opt

-- ========================================
-- 기본 편집 설정
-- ========================================

opt.termguicolors = true -- True color
opt.number = true -- 라인 번호
opt.relativenumber = true -- 상대 라인 번호
opt.signcolumn = "yes" -- 사인 컬럼 항상 표시
opt.cursorline = true -- 커서 라인 강조

-- ========================================
-- 공백 및 들여쓰기
-- ========================================

opt.expandtab = true -- 탭을 스페이스로
opt.shiftwidth = 2 -- 들여쓰기 너비
opt.tabstop = 2 -- 탭 너비
opt.smartindent = true -- 스마트 들여쓰기

-- ========================================
-- 검색
-- ========================================

opt.ignorecase = true -- 대소문자 무시
opt.smartcase = true -- 대문자 포함 시 대소문자 구분

-- ========================================
-- UI 개선
-- ========================================

opt.scrolloff = 8 -- 스크롤 여백
opt.sidescrolloff = 8
opt.pumheight = 15 -- 팝업 메뉴 높이
opt.colorcolumn = "100" -- 100자 가이드

opt.splitright = true -- 수직 분할 오른쪽
opt.splitbelow = true -- 수평 분할 아래

opt.wrap = false -- 줄바꿈 비활성화
opt.linebreak = true -- 단어 단위 줄바꿈

-- ========================================
-- 시각적 요소
-- ========================================

opt.list = true
opt.listchars = {
  tab = "→ ",
  trail = "·",
  nbsp = "␣",
}

opt.fillchars = {
  eob = " ", -- 버퍼 끝 비우기
  vert = "│", -- 수직 분할선
}

-- ========================================
-- 타이밍
-- ========================================

opt.updatetime = 200 -- 빠른 업데이트
opt.timeoutlen = 300 -- 키 입력 대기 시간
