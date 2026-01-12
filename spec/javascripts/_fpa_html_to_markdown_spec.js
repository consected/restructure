//= require app/_fpa_utils.js

describe('_fpa.utils.html_to_markdown', function () {
  describe('basic HTML to markdown conversion', function () {
    it('converts simple paragraphs to markdown', function () {
      var obj = { html: '<p>Hello World</p>' };
      var result = _fpa.utils.html_to_markdown(obj);
      expect(result).toContain('Hello World');
    });

    it('converts bold text to markdown', function () {
      var obj = { html: '<p><b>Bold text</b></p>' };
      var result = _fpa.utils.html_to_markdown(obj);
      expect(result).toContain('Bold text');
      // domador converts <b> to **text**
      expect(result).toMatch(/\*\*Bold text\*\*/);
    });

    it('converts italic text to markdown', function () {
      var obj = { html: '<p><i>Italic text</i></p>' };
      var result = _fpa.utils.html_to_markdown(obj);
      expect(result).toContain('Italic text');
    });

    it('converts underlined text to markdown', function () {
      var obj = { html: '<p><u>Underlined text</u></p>' };
      var result = _fpa.utils.html_to_markdown(obj);
      expect(result).toContain('Underlined text');
    });

    it('converts headings to markdown', function () {
      var obj = { html: '<h1>Heading 1</h1><h2>Heading 2</h2>' };
      var result = _fpa.utils.html_to_markdown(obj);
      expect(result).toContain('Heading 1');
      expect(result).toContain('Heading 2');
    });

    it('converts links to markdown', function () {
      var obj = { html: '<p><a href="https://example.com">Example Link</a></p>' };
      var result = _fpa.utils.html_to_markdown(obj);
      expect(result).toContain('Example Link');
      expect(result).toContain('https://example.com');
    });
  });

  describe('preserves all text content when removing formatting', function () {
    it('preserves text from multiple paragraphs', function () {
      var obj = {
        html: '<p>First paragraph.</p><p>Second paragraph.</p><p>Third paragraph.</p>'
      };
      var result = _fpa.utils.html_to_markdown(obj);
      expect(result).toContain('First paragraph');
      expect(result).toContain('Second paragraph');
      expect(result).toContain('Third paragraph');
    });

    it('preserves text when removing span elements', function () {
      var obj = {
        html: '<p><span>Text in span</span> and more text.</p>'
      };
      var result = _fpa.utils.html_to_markdown(obj);
      expect(result).toContain('Text in span');
      expect(result).toContain('and more text');
    });

    it('preserves text when removing font elements', function () {
      var obj = {
        html: '<p><font color="red">Colored text</font> and normal text.</p>'
      };
      var result = _fpa.utils.html_to_markdown(obj);
      expect(result).toContain('Colored text');
      expect(result).toContain('and normal text');
    });
  });

  describe('handles Microsoft Word (MsoNormal) formatting', function () {
    it('preserves all paragraphs from MsoNormal class content', function () {
      var obj = {
        html: `<p class="MsoNormal">
The overall goal of the proposed project is to refine the definition .... Our specific aims are:
</p>
<p class="MsoNormal">
<b><u>Aim 1:</u></b> Develop comprehensive measures. Lorem ipsum.
</p>
<p class="MsoNormal">
<b><u>Aim 2:</u></b> Examine features... Develop comprehensive measures. Lorem ipsum
</p>
<p class="MsoNormal">
<b><u>Aim 3:</u></b> Lorem ipsum..
</p>`
      };
      var result = _fpa.utils.html_to_markdown(obj);

      // All paragraphs should be preserved
      expect(result).toContain('overall goal');
      expect(result).toContain('specific aims are');
      expect(result).toContain('Aim 1');
      expect(result).toContain('Develop comprehensive measures');
      expect(result).toContain('Aim 2');
      expect(result).toContain('Examine features');
      expect(result).toContain('Aim 3');
      expect(result).toContain('Lorem ipsum');
    });

    it('preserves all text from complex Word formatting with spans and styles', function () {
      var obj = {
        html: `<p class="MsoNormal" style="margin: 0;"><span style="font-family: Calibri;">Introduction text here.</span></p>
<p class="MsoNormal" style="margin: 0;"><span style="font-family: Calibri;"><b>Section 1:</b> Details about section one.</span></p>
<p class="MsoNormal" style="margin: 0;"><span style="font-family: Calibri;"><b>Section 2:</b> Details about section two.</span></p>`
      };
      var result = _fpa.utils.html_to_markdown(obj);

      expect(result).toContain('Introduction text here');
      expect(result).toContain('Section 1');
      expect(result).toContain('Details about section one');
      expect(result).toContain('Section 2');
      expect(result).toContain('Details about section two');
    });

    it('preserves content from paragraphs with o:p tags (Word empty paragraph markers)', function () {
      // o:p is a namespaced XML tag from Microsoft Office that can cause parsing issues
      var obj = {
        html: '<p class="MsoNormal">First paragraph content<o:p></o:p></p><p class="MsoNormal">Second paragraph content<o:p></o:p></p><p class="MsoNormal">Third paragraph content<o:p></o:p></p>'
      };

      var result = _fpa.utils.html_to_markdown(obj);

      expect(result).toContain('First paragraph content');
      expect(result).toContain('Second paragraph content');
      expect(result).toContain('Third paragraph content');
    });

    it('preserves all content from complex Word HTML with spans and empty underline tags', function () {
      // Real-world example from Word paste
      var obj = {
        html: `<div>
<p class="MsoNormal"><span style="font-size:11.0pt">The overall goal of the proposed project is to refine the definition of positive health in a longitudinal cohort of adolescents and characterize cross-sectional associations with neighborhood environmental
 determinants. To achieve this goal, we will leverage multiple measures of positive health from adolescents participating in the Project Viva pre-birth cohort study. Our specific aims are:
<u></u><u></u></span></p>
<p class="MsoNormal"><b><u><span style="font-size:11.0pt">Aim 1:</span></u></b><span style="font-size:11.0pt"> Develop comprehensive measures of positive health at two timepoints in adolescence, leveraging multiple parent-reported, self-reported, and research-measured
 metrics. We will generate composite measures of biological, behavioral, functional, and experiential health as well as healthful lifestyle behaviors using both concept-driven and data-driven approaches. We will then derive a global measure of positive health
 incorporating all of these domains.<u></u><u></u></span></p>
<p class="MsoNormal"><b><u><span style="font-size:11.0pt">Aim 2:</span></u></b><span style="font-size:11.0pt"> Examine features of the neighborhood environment that are cross-sectionally associated with the newly derived measures of positive health at both
 early and mid-late adolescence<u></u><u></u></span></p>
<p class="MsoNormal"><b><u><span style="font-size:11.0pt">Aim 3:</span></u></b><span style="font-size:11.0pt"> Using these newly derived positive health measures, develop a future stream of research into the upstream predictors and downstream sequelae of positive
 health across adolescence that leverages the strengths of our longitudinal pre-birth cohort.
<u></u><u></u></span></p>
</div>`
      };

      var result = _fpa.utils.html_to_markdown(obj);

      // All main content should be preserved
      expect(result).toContain('overall goal');
      expect(result).toContain('positive health');
      expect(result).toContain('specific aims are');
      expect(result).toContain('Aim 1');
      expect(result).toContain('Develop comprehensive measures');
      expect(result).toContain('Aim 2');
      expect(result).toContain('Examine features');
      expect(result).toContain('neighborhood environment');
      expect(result).toContain('Aim 3');
      expect(result).toContain('longitudinal pre-birth cohort');
    });
  });

  describe('handles nested formatting correctly', function () {
    it('preserves text with nested bold and underline', function () {
      var obj = {
        html: '<p><b><u>Bold and underlined</u></b> followed by normal text.</p>'
      };
      var result = _fpa.utils.html_to_markdown(obj);
      expect(result).toContain('Bold and underlined');
      expect(result).toContain('followed by normal text');
    });

    it('preserves text from deeply nested elements', function () {
      var obj = {
        html: '<div><div><p><span><b><i>Deeply nested text</i></b></span></p></div></div>'
      };
      var result = _fpa.utils.html_to_markdown(obj);
      expect(result).toContain('Deeply nested text');
    });
  });

  describe('removes unwanted elements while preserving content', function () {
    it('removes script tags but keeps surrounding content', function () {
      var obj = {
        html: '<p>Before script</p><script>alert("test")</script><p>After script</p>'
      };
      var result = _fpa.utils.html_to_markdown(obj);
      expect(result).toContain('Before script');
      expect(result).toContain('After script');
      expect(result).not.toContain('alert');
    });

    it('removes style attributes while keeping text', function () {
      var obj = {
        html: '<p style="color: red; font-size: 20px;">Styled text content</p>'
      };
      var result = _fpa.utils.html_to_markdown(obj);
      expect(result).toContain('Styled text content');
    });

    it('removes class attributes while keeping text', function () {
      var obj = {
        html: '<p class="custom-class another-class">Text with classes</p>'
      };
      var result = _fpa.utils.html_to_markdown(obj);
      expect(result).toContain('Text with classes');
    });
  });

  describe('handles whitespace and formatting correctly', function () {
    it('handles multiple spaces and newlines', function () {
      var obj = {
        html: '<p>Text with    multiple   spaces</p>'
      };
      var result = _fpa.utils.html_to_markdown(obj);
      expect(result).toContain('Text with');
      expect(result).toContain('multiple');
      expect(result).toContain('spaces');
    });

    it('handles nbsp entities', function () {
      var obj = {
        html: '<p>Text&nbsp;with&nbsp;nbsp</p>'
      };
      var result = _fpa.utils.html_to_markdown(obj);
      expect(result).toContain('Text');
      expect(result).toContain('with');
      expect(result).toContain('nbsp');
    });
  });

  describe('handles tables correctly', function () {
    it('preserves table content', function () {
      var obj = {
        html: '<table><tr><td>Cell 1</td><td>Cell 2</td></tr><tr><td>Cell 3</td><td>Cell 4</td></tr></table>'
      };
      var result = _fpa.utils.html_to_markdown(obj);
      expect(result).toContain('Cell 1');
      expect(result).toContain('Cell 2');
      expect(result).toContain('Cell 3');
      expect(result).toContain('Cell 4');
    });
  });

  describe('handles lists correctly', function () {
    it('preserves ordered list content', function () {
      var obj = {
        html: '<ol><li>First item</li><li>Second item</li><li>Third item</li></ol>'
      };
      var result = _fpa.utils.html_to_markdown(obj);
      expect(result).toContain('First item');
      expect(result).toContain('Second item');
      expect(result).toContain('Third item');
    });

    it('preserves unordered list content', function () {
      var obj = {
        html: '<ul><li>Item A</li><li>Item B</li><li>Item C</li></ul>'
      };
      var result = _fpa.utils.html_to_markdown(obj);
      expect(result).toContain('Item A');
      expect(result).toContain('Item B');
      expect(result).toContain('Item C');
    });
  });

  describe('handles edge cases', function () {
    it('handles empty paragraphs gracefully', function () {
      var obj = {
        html: '<p>Real content</p><p></p><p>More content</p>'
      };
      var result = _fpa.utils.html_to_markdown(obj);
      expect(result).toContain('Real content');
      expect(result).toContain('More content');
    });

    it('handles paragraph with only whitespace', function () {
      var obj = {
        html: '<p>Real content</p><p>   </p><p>More content</p>'
      };
      var result = _fpa.utils.html_to_markdown(obj);
      expect(result).toContain('Real content');
      expect(result).toContain('More content');
    });

    it('handles mixed content correctly', function () {
      var obj = {
        html: `<h1>Title</h1>
<p>Introduction paragraph with <b>bold</b> and <i>italic</i> text.</p>
<ul>
  <li>First point</li>
  <li>Second point</li>
</ul>
<p>Conclusion paragraph.</p>`
      };
      var result = _fpa.utils.html_to_markdown(obj);
      expect(result).toContain('Title');
      expect(result).toContain('Introduction paragraph');
      expect(result).toContain('bold');
      expect(result).toContain('italic');
      expect(result).toContain('First point');
      expect(result).toContain('Second point');
      expect(result).toContain('Conclusion paragraph');
    });
  });
});
