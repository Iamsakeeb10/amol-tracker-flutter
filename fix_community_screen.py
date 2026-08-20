with open('lib/features/community/presentation/screens/community_screen.dart', 'r') as f:
    content = f.read()

# 1. Normal View Top
normal_top_find = """                      Expanded(
                        child: fieldsAsync.isLoading"""

normal_top_repl = """                      Expanded(
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppRadius.md.r,
                              ),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: CommunityHeaderRow(
                                  horizontalController:
                                      _headerHorizontalController,
                                  fields: fields,
                                  locale: locale,
                                ),
                              ),
                            ),
                            Expanded(
                              child: fieldsAsync.isLoading"""

if normal_top_find in content:
    content = content.replace(normal_top_find, normal_top_repl, 1)

# 2. Normal View Middle
normal_mid_find = """                                controller: _verticalController,
                                slivers: [
                                  SliverPersistentHeader(
                                    pinned: true,
                                    delegate: _StickyHeaderDelegate(
                                      minHeight: kCommunityHeaderRowHeight.h,
                                      maxHeight: kCommunityHeaderRowHeight.h,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.md.r,
                                        ),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                          child: CommunityHeaderRow(
                                            horizontalController:
                                                _headerHorizontalController,
                                            fields: fields,
                                            locale: locale,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),"""

normal_mid_repl = """                                controller: _verticalController,
                                slivers: ["""

if normal_mid_find in content:
    content = content.replace(normal_mid_find, normal_mid_repl, 1)

# 3. Normal View Bottom
normal_bottom_find = """                                ],
                              ),
                          ),
                        ),
                      ],
                    ),
                  const _ActivityFeedTab(),"""

normal_bottom_repl = """                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              const _ActivityFeedTab(),"""

if normal_bottom_find in content:
    content = content.replace(normal_bottom_find, normal_bottom_repl, 1)

# 4. Full Screen Top
fs_top_find = """              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: fieldsAsync.isLoading || state.isLoading"""

fs_top_repl = """              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppRadius.md.r,
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: CommunityHeaderRow(
                            horizontalController:
                                _headerHorizontalController,
                            fields: fields,
                            locale: locale,
                          ),
                        ),
                      ),
                      Expanded(
                        child: fieldsAsync.isLoading || state.isLoading"""

if fs_top_find in content:
    content = content.replace(fs_top_find, fs_top_repl, 1)

# 5. Full Screen Middle
fs_mid_find = """                            controller: _verticalController,
                            slivers: [
                              SliverPersistentHeader(
                                pinned: true,
                                delegate: _StickyHeaderDelegate(
                                  minHeight: kCommunityHeaderRowHeight.h,
                                  maxHeight: kCommunityHeaderRowHeight.h,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.md.r,
                                    ),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                      child: CommunityHeaderRow(
                                        horizontalController:
                                            _headerHorizontalController,
                                        fields: fields,
                                        locale: locale,
                                      ),
                                    ),
                                  ),
                                ),
                              ),"""

fs_mid_repl = """                            controller: _verticalController,
                            slivers: ["""

if fs_mid_find in content:
    content = content.replace(fs_mid_find, fs_mid_repl, 1)

# 6. Full Screen Bottom
fs_bottom_find = """                            ],
                          ),
                      ),
                ),
              ),
            ],"""

fs_bottom_repl = """                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],"""

if fs_bottom_find in content:
    content = content.replace(fs_bottom_find, fs_bottom_repl, 1)

with open('lib/features/community/presentation/screens/community_screen.dart', 'w') as f:
    f.write(content)
