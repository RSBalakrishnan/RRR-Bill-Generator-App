import os
from fpdf import FPDF

class TransportBillTester(FPDF):
    def __init__(self, template_path):
        super().__init__(format='A4', unit='pt')
        self.template_path = template_path

    def add_standard_layout(self, billed_to, date):
        self.add_page()
        # Background
        if os.path.exists(self.template_path):
            self.image(self.template_path, x=0, y=0, w=self.w, h=self.h)
        
        # To Section (Moved 1cm higher ~28.3pt from previous 260pt)
        self.set_y(231.7)
        self.set_left_margin(40)
        self.set_right_margin(40)
        
        # Billed To
        self.set_text_color(128, 128, 128)
        self.set_font("helvetica", "B", 10)
        self.cell(0, 15, "To:", ln=True)
        self.set_font("helvetica", "", 12)
        self.cell(0, 15, billed_to, ln=True)
        
        # Date (Right aligned, kept relative to To section)
        self.set_y(246.7)
        self.set_text_color(128, 128, 128)
        self.set_font("helvetica", "", 12)
        self.cell(0, 15, f"Date: {date}", align='R', ln=True)
        self.set_text_color(0, 0, 0) # Reset before title
        
        self.ln(20)
        
        # Title (Reduced size)
        self.set_text_color(128, 128, 128) # Grey
        self.set_font("helvetica", "B", 12)
        self.cell(0, 20, "Base Freight Charge", align='C', ln=True)
        self.ln(10)

    def draw_table(self, items, is_static=False):
        # Column widths matching Dart exactly (Updated Lorry No)
        cols = [55, 85, 60, 55, 35, 100, 50, 60]
        headers = ["Date", "Lorry No.", "Material", "Challan", "Trips", "Site", "Rate", "Amount"]
        
        # Header
        self.set_font("helvetica", "B", 10)
        self.set_text_color(0, 0, 0)
        for i, header in enumerate(headers):
            self.cell(cols[i], 25, header, border=1, align='C')
        self.ln()
        
        # Items
        self.set_font("helvetica", "", 10)
        self.set_text_color(0, 0, 0)
        total_trips = 0
        total_amount = 0
        
        row_count = 10 if is_static else len(items)
        
        for i in range(row_count):
            if i < len(items):
                item = items[i]
                total_trips += item['trips']
                total_amount += item['trips'] * item['rate']
                
                self.cell(cols[0], 25, item['date'], border=1, align='C')
                self.cell(cols[1], 25, item['lorry'], border=1, align='C')
                self.cell(cols[2], 25, item['material'], border=1, align='C')
                self.cell(cols[3], 25, item['challan'], border=1, align='C')
                self.cell(cols[4], 25, str(item['trips']), border=1, align='C')
                self.cell(cols[5], 25, item['site'], border=1, align='C')
                self.cell(cols[6], 25, str(item['rate']), border=1, align='C')
                self.cell(cols[7], 25, str(item['trips'] * item['rate']), border=1, align='C')
                self.ln()
            else:
                # Empty rows for Template 3
                for width in cols:
                    self.cell(width, 25, "", border=1)
                self.ln()
                
        # Footer / Totals
        self.set_font("helvetica", "B", 10)
        self.set_text_color(0, 0, 0)
        self.cell(sum(cols[:4]), 25, "", border=0) # Space
        self.cell(cols[4], 25, f"{total_trips} trips", border=1, align='C')
        self.cell(cols[5], 25, "", border=0) # Space
        self.set_text_color(128, 128, 128)
        self.cell(cols[6], 25, "TOTAL", border=1, align='C')
        self.set_text_color(0, 0, 0) # Amount now black
        self.cell(cols[7], 25, str(total_amount), border=1, align='C')
        self.ln(25)
        self.draw_rupees_in_words(total_amount)

    def draw_rupees_in_words(self, amount):
        # Shared method to ensure it appears in all templates
        self.ln(5)
        curr_y = self.get_y()
        self.set_left_margin(40)
        self.rect(40, curr_y, self.w - 80, 30)
        self.set_y(curr_y + 8)
        self.set_x(50)
        self.set_font("helvetica", "B", 10)
        self.set_text_color(128, 128, 128)
        self.cell(120, 15, "RUPEES IN WORDS: ", border=0)
        self.set_text_color(0, 0, 0)
        self.cell(0, 15, "SAMPLE RUPEES IN WORDS ONLY", border=0)
        self.ln(25)

    def add_signature(self):
        # Position signature lower (Further from content, closer to bottom)
        self.set_y(self.h - 90) # Adjusted to be slightly lower
        self.set_x(self.w - 200)
        self.set_font("helvetica", "B", 12)
        self.set_text_color(128, 128, 128)
        self.cell(160, 15, "Proprietor Sign", align='C', ln=True)
        self.set_text_color(0, 0, 0)


    def add_compact_layout(self, bill_no, billed_to, date):
        self.add_page()
        if os.path.exists(self.template_path):
            self.image(self.template_path, x=0, y=0, w=self.w, h=self.h)
        
        self.set_y(230)
        self.set_left_margin(40)
        self.set_right_margin(40)
        
        # Bill No (Label width 50, Total 180 as in Dart)
        self.set_text_color(128, 128, 128) 
        self.set_font("helvetica", "B", 11)
        self.cell(50, 20, "Bill No.")
        self.set_text_color(0, 0, 0)
        self.cell(130, 20, f"  {bill_no}", border='B')
        
        # Date (Label width 40, Total 150 as in Dart)
        self.set_x(self.w - 190) # Adjust position to fit 150pt width
        self.set_text_color(128, 128, 128)
        self.cell(40, 20, "Date")
        self.set_text_color(0, 0, 0)
        self.cell(110, 20, f"  {date}", border='B', ln=True)
        
        self.ln(10)
        
        # To Section (Label width 50, Full width as in Dart)
        self.set_text_color(128, 128, 128)
        self.cell(50, 20, "To,")
        self.set_text_color(0, 0, 0)
        self.cell(0, 20, f"  {billed_to}", border='B', ln=True)
        
        self.ln(10)
        self.set_text_color(128, 128, 128) # Grey
        self.set_font("helvetica", "B", 12)
        self.cell(0, 20, "Base Freight Charge", align='C', ln=True)
        self.ln(5)

    def draw_compact_table(self, items):
        # Smaller font and padding for T4
        cols = [70, 80, 60, 55, 35, 100, 50, 60]
        headers = ["Date", "Lorry No.", "Material", "Challan", "Trips", "Site", "Rate", "Amount"]
        
        self.set_font("helvetica", "B", 9)
        self.set_text_color(0, 0, 0)
        for i, h in enumerate(headers):
            self.cell(cols[i], 20, h, border=1, align='C')
        self.ln()
        
        self.set_font("helvetica", "", 9)
        self.set_text_color(0, 0, 0)
        t_trips, t_amt = 0, 0
        for i in range(20): # Fixed 20 compact rows (Increased)
            if i < len(items):
                it = items[i]
                t_trips += it['trips']
                t_amt += it['trips'] * it['rate']
                row = [it['date'], it['lorry'], it['material'], it['challan'], str(it['trips']), it['site'], str(it['rate']), str(it['trips']*it['rate'])]
                for idx, val in enumerate(row):
                    self.cell(cols[idx], 18, val, border=1, align='C')
                self.ln()
            else:
                for w in cols: self.cell(w, 18, "", border=1)
                self.ln()
        
        # Summary
        self.set_font("helvetica", "B", 9)
        self.set_text_color(0, 0, 0)
        self.cell(sum(cols[:4]), 20, "")
        self.cell(cols[4], 20, f"{t_trips} trips", border=1, align='C')
        self.cell(cols[5], 20, "")
        self.set_text_color(128, 128, 128)
        self.cell(cols[6], 20, "TOTAL", border=1, align='C')
        self.set_text_color(0, 0, 0) # Amount now black
        self.cell(cols[7], 20, str(t_amt), border=1, align='C')
        self.ln(30) # Space exactly below table for Rupees
        
        self.draw_rupees_in_words(t_amt)
        
        # Signing gap
        self.ln(40)
        self.set_text_color(128, 128, 128)
        self.set_font("helvetica", "B", 11)
        self.cell(0, 15, "Proprietor Sign", align='R', ln=True)

# Sample Execution
if __name__ == "__main__":
    sample_data = [
        {"date": "19/04/2026", "lorry": "MH 02 GS 1234", "material": "DEBRIS", "challan": "456", "trips": 2, "site": "BKC SITE", "rate": 5000},
        {"date": "20/04/2026", "lorry": "MH 02 FG 5678", "material": "DEBRIS", "challan": "457", "trips": 1, "site": "TIMES TOWER", "rate": 5000},
    ]
    
    # Generate Template 2 (Dynamic)
    pdf2 = TransportBillTester("transport-bill-template.png")
    pdf2.add_standard_layout("ABC Constructions Pvt Ltd", "19/04/2026")
    pdf2.draw_table(sample_data, is_static=False)
    pdf2.add_signature()
    pdf2.output("test_template_2_dynamic.pdf")
    
    # Generate Template 3 (Static)
    pdf3 = TransportBillTester("transport-bill-template.png")
    pdf3.add_standard_layout("ABC Constructions Pvt Ltd", "19/04/2026")
    pdf3.draw_table(sample_data, is_static=True)
    pdf3.add_signature()
    pdf3.output("test_template_3_static.pdf")
    
    # Generate Template 4 (Compact)
    pdf4 = TransportBillTester("transport-bill-template.png")
    pdf4.add_compact_layout("036", "NARSI INTERIOR INFRASTRUCTURE PVT. LTD.", "15/04/2026")
    pdf4.draw_compact_table(sample_data)
    pdf4.add_signature()
    pdf4.output("test_template_4_compact.pdf")
    print("Generated all test PDFs including Template 4")
