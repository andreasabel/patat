--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
module Patat.Presentation.Display.Table
    ( Table (..)
    , prettyTable

    , themed
    ) where


--------------------------------------------------------------------------------
import           Data.List                           (intersperse, transpose)
import           Patat.Presentation.Display.Internal
import           Patat.PrettyPrint                   ((<$$>))
import qualified Patat.PrettyPrint                   as PP
import           Patat.Theme                         (Theme (..))
import           Prelude


--------------------------------------------------------------------------------
data Table = Table
    { tCaption :: PP.Doc
    , tAligns  :: [PP.Alignment]
    , tHeaders :: [PP.Doc]
    , tRows    :: [[PP.Doc]]
    }


--------------------------------------------------------------------------------
prettyTable :: DisplaySettings -> Table -> PP.Doc
prettyTable ds Table {..} =
    PP.indent (PP.Trimmable "  ") (PP.Trimmable "  ") $
        lineIf (not isHeaderLess) (hcat2 headerHeight
            [ themed ds themeTableHeader $
                PP.align w a (vpad headerHeight header)
            | (w, a, header) <- zip3 columnWidths tAligns tHeaders
            ]) <>
        dashedHeaderSeparator ds columnWidths <$$>
        joinRows
            [ hcat2 rowHeight
                [ PP.align w a (vpad rowHeight cell)
                | (w, a, cell) <- zip3 columnWidths tAligns row
                ]
            | (rowHeight, row) <- zip rowHeights tRows
            ] <$$>
        lineIf isHeaderLess (dashedHeaderSeparator ds columnWidths) <>
        lineIf
            (not $ PP.null tCaption) (PP.hardline <> "Table: " <> tCaption)
  where
    lineIf cond line = if cond then line <> PP.hardline else mempty

    joinRows
        | all (all isSimpleCell) tRows = PP.vcat
        | otherwise                    = PP.vcat . intersperse ""

    isHeaderLess = all PP.null tHeaders

    headerDimensions = map PP.dimensions tHeaders :: [(Int, Int)]
    rowDimensions    = map (map PP.dimensions) tRows :: [[(Int, Int)]]

    columnWidths :: [Int]
    columnWidths =
        [ safeMax (map snd col)
        | col <- transpose (headerDimensions : rowDimensions)
        ]

    rowHeights   = map (safeMax . map fst) rowDimensions :: [Int]
    headerHeight = safeMax (map fst headerDimensions)    :: Int

    vpad :: Int -> PP.Doc -> PP.Doc
    vpad height doc =
        let (actual, _) = PP.dimensions doc in
        doc <> mconcat (replicate (height - actual) PP.hardline)

    safeMax = foldr max 0

    hcat2 :: Int -> [PP.Doc] -> PP.Doc
    hcat2 rowHeight = PP.paste . intersperse (spaces2 rowHeight)

    spaces2 :: Int -> PP.Doc
    spaces2 rowHeight =
        mconcat $ intersperse PP.hardline $
        replicate rowHeight (PP.string "  ")


--------------------------------------------------------------------------------
isSimpleCell :: PP.Doc -> Bool
isSimpleCell = (<= 1) . fst . PP.dimensions


--------------------------------------------------------------------------------
dashedHeaderSeparator :: DisplaySettings -> [Int] -> PP.Doc
dashedHeaderSeparator ds columnWidths =
    mconcat $ intersperse (PP.string "  ")
        [ themed ds themeTableSeparator (PP.string (replicate w '-'))
        | w <- columnWidths
        ]
